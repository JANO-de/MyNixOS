import QtQuick
import Quickshell
import qs.services

// Settings > Apps: every installed app with two switches-as-pills: In dock / On home screen.
Column {
    id: page

    // Bumped after Home changes: ListModel.get() inside a binding does not register a dependency.
    property int tick: 0
    property var apps: {
        const list = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay || Apps.blocked(e))
                continue;
            list.push(e);
        }
        list.sort((a, b) => String(a.name).localeCompare(String(b.name)));
        return list;
    }

    width: parent ? parent.width : 600
    spacing: 22

    // Per-app info page (like Android's App info): shown while UI.appInfoId is set.
    readonly property var info: UI.appInfoId !== "" ? DesktopEntries.heuristicLookup(UI.appInfoId) : null
    readonly property var infoItem: {
        if (!info)
            return null;
        for (const i of Apps.items)
            if (i.entry && i.entry.id === info.id)
                return i;
        return null;
    }
    readonly property var infoWins: infoItem ? infoItem.windows : []

    SetGroup {
        visible: !page.info
        title: page.apps.length + " apps"

        Repeater {
            model: page.apps

            SetRow {
                id: row

                required property var modelData
                readonly property bool inDock: Apps.isPinned(modelData)
                readonly property bool onHome: {
                    page.tick;
                    Home.icons.count;
                    return Home.indexOfIcon(modelData.id) >= 0 || !!Home.folderedIds()[modelData.id];
                }

                icon: String(modelData.icon || "")
                title: modelData.name
                subtitle: (inDock ? "In dock" : "Not in dock") + "  ·  " + (onHome ? "On home screen" : "Not on home screen")
                tappable: true
                chevron: true
                onClicked: UI.appInfoId = modelData.id

                Row {
                    spacing: 8

                    SetButton {
                        text: "Dock"
                        accent: row.inDock
                        onClicked: {
                            if (row.inDock)
                                Apps.unpinEntry(row.modelData);
                            else
                                Apps.pin(row.modelData);
                        }
                    }
                    SetButton {
                        text: "Home"
                        accent: row.onHome
                        onClicked: {
                            const i = Home.indexOfIcon(row.modelData.id);
                            if (i >= 0)
                                Home.hideIconAt(i);
                            else if (!Home.folderedIds()[row.modelData.id])
                                Home.addToHome(row.modelData.id);
                            page.tick++;
                        }
                    }
                }
            }
        }
    }

    Text {
        visible: !page.info
        width: parent.width
        leftPadding: 8
        rightPadding: 8
        text: "Apps inside a folder count as on the home screen; open the folder to take them out."
        color: Theme.dim
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }

    // ---- App info page ---------------------------------------------------------------------------
    Column {
        id: detail
        visible: !!page.info
        width: parent.width
        spacing: 22

        SetButton {
            text: "\u2039 Apps"
            onClicked: UI.appInfoId = ""
        }

        Row {
            spacing: 18
            Image {
                width: 72
                height: 72
                source: page.info ? Apps.iconSource(page.info.icon) : ""
                sourceSize: Qt.size(144, 144)
                fillMode: Image.PreserveAspectFit
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Text {
                    text: page.info ? page.info.name : ""
                    color: Theme.text
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                }
                Text {
                    visible: text !== ""
                    text: page.info ? (page.info.comment || page.info.genericName || "") : ""
                    color: Theme.dim
                    font.pixelSize: 14
                }
            }
        }

        Row {
            spacing: 10
            SetButton {
                text: "Open"
                accent: true
                onClicked: {
                    UI.closeSettings();
                    if (page.infoItem)
                        Apps.activateNow(page.infoItem);
                    else if (page.info)
                        Home.launch(page.info);
                }
            }
            SetButton {
                text: "Force stop"
                danger: true
                visible: page.infoWins.length > 0
                onClicked: {
                    for (const w of page.infoWins)
                        w.close();
                }
            }
        }

        SetGroup {
            title: "Shortcuts"
            SetRow {
                title: "In dock"
                tappable: false
                SetButton {
                    readonly property bool isOn: page.info ? Apps.isPinned(page.info) : false
                    text: isOn ? "Remove" : "Add"
                    accent: !isOn
                    onClicked: {
                        if (isOn)
                            Apps.unpinEntry(page.info);
                        else
                            Apps.pin(page.info);
                    }
                }
            }
            SetRow {
                title: "On home screen"
                tappable: false
                SetButton {
                    readonly property bool isOn: {
                        page.tick;
                        Home.icons.count;
                        return page.info ? (Home.indexOfIcon(page.info.id) >= 0 || !!Home.folderedIds()[page.info.id]) : false;
                    }
                    text: isOn ? "Remove" : "Add"
                    accent: !isOn
                    onClicked: {
                        const i = Home.indexOfIcon(page.info.id);
                        if (i >= 0)
                            Home.hideIconAt(i);
                        else if (!Home.folderedIds()[page.info.id])
                            Home.addToHome(page.info.id);
                        page.tick++;
                    }
                }
            }
        }

        SetGroup {
            title: "Details"
            SetRow {
                title: "Status"
                subtitle: page.infoWins.length > 0 ? "Running, " + page.infoWins.length + (page.infoWins.length === 1 ? " window" : " windows") : "Not running"
                tappable: false
            }
            SetRow {
                title: "Command"
                subtitle: page.info ? (page.info.command || []).join(" ") : ""
                tappable: false
            }
            SetRow {
                title: "Categories"
                subtitle: page.info ? (page.info.categories || []).join(", ") : ""
                visible: subtitle !== ""
                tappable: false
            }
            SetRow {
                title: "Desktop entry"
                subtitle: page.info ? page.info.id : ""
                tappable: false
            }
        }
    }
}

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

    SetGroup {
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
                tappable: false

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
        width: parent.width
        leftPadding: 8
        rightPadding: 8
        text: "Apps inside a folder count as on the home screen; open the folder to take them out."
        color: Theme.dim
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// App launcher overlay (SUPER+A, dock button): clock, search and the full app grid.
// The always-visible home screen with icons and widgets is components/Desktop.qml.
PanelWindow {
    id: root

    readonly property bool shown: UI.homeOpen
    readonly property int dockSpace: Mode.tablet ? 120 : 104

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    visible: shown || content.opacity > 0.01
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-home"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onShownChanged: {
        menuEntry = null;
        if (shown) {
            search.text = "";
            search.focus = false; // search only when tapped
        }
    }

    function filtered() {
        const q = search.text.trim().toLowerCase();
        const list = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay)
                continue;
            if (q !== "" && String(e.name).toLowerCase().indexOf(q) < 0)
                continue;
            list.push(e);
        }
        list.sort((a, b) => String(a.name).localeCompare(String(b.name)));
        return list;
    }

    property var apps: filtered()

    // Long-press menu state (Open / Add to or Remove from Home Screen).
    property var menuEntry: null
    property point menuAt: Qt.point(0, 0)
    readonly property bool menuInFolder: menuEntry ? !!Home.folderedIds()[menuEntry.id] : false
    readonly property bool menuOnHome: menuEntry ? (Home.indexOfIcon(menuEntry.id) >= 0 || menuInFolder) : false

    function launch(entry) {
        UI.closeHome();
        Home.launch(entry);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: content
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.menuEntry)
                    root.menuEntry = null;
                else
                    UI.closeHome();
            }
        }

        Item {
            id: stage
            anchors.fill: parent
            scale: root.shown ? 1 : 1.05
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Column {
                id: header
                anchors.top: parent.top
                anchors.topMargin: 64
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Theme.text
                    font.pixelSize: 72
                    font.weight: Font.Light
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Theme.dim
                    font.pixelSize: 18
                }
            }

            Rectangle {
                id: searchBox
                anchors.top: header.bottom
                anchors.topMargin: 28
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width * 0.6, 520)
                height: 44
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.14)

                Text {
                    anchors.centerIn: parent
                    visible: search.text === ""
                    text: "Search"
                    color: Theme.dim
                    font.pixelSize: 16
                }

                TextInput {
                    id: search
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.pixelSize: 16
                    clip: true
                    onAccepted: {
                        if (root.apps.length > 0)
                            root.launch(root.apps[0]);
                    }
                    Keys.onEscapePressed: UI.closeHome()
                }
            }

            GridView {
                id: grid
                anchors.top: searchBox.bottom
                anchors.topMargin: 32
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.dockSpace
                anchors.horizontalCenter: parent.horizontalCenter
                cellWidth: Home.cellW
                cellHeight: Home.cellH
                width: Math.max(1, Math.floor((parent.width - 80) / cellWidth)) * cellWidth
                clip: true
                model: root.apps

                delegate: AppIcon {
                    required property var modelData
                    width: grid.cellWidth
                    height: grid.cellHeight
                    entry: modelData
                    onActivated: {
                        if (root.menuEntry)
                            root.menuEntry = null;
                        else
                            root.launch(modelData);
                    }
                    onLongPressed: {
                        root.menuAt = mapToItem(stage, width / 2, 0);
                        root.menuEntry = modelData;
                    }
                }
            }

            Column {
                id: iconMenu
                visible: root.menuEntry !== null
                z: 5
                width: 240
                spacing: 4
                x: Math.max(12, Math.min(stage.width - width - 12, root.menuAt.x - width / 2))
                y: Math.max(12, Math.min(stage.height - height - 12, root.menuAt.y - height - 8))

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 14
                    color: openTap.pressed ? Theme.surfacePress : Theme.surfaceHigh
                    Text {
                        anchors.centerIn: parent
                        text: "Open"
                        color: Theme.text
                        font.pixelSize: 15
                    }
                    MouseArea {
                        id: openTap
                        anchors.fill: parent
                        onClicked: {
                            const e = root.menuEntry;
                            root.menuEntry = null;
                            if (e)
                                root.launch(e);
                        }
                    }
                }

                Rectangle {
                    visible: !root.menuOnHome
                    width: parent.width
                    height: 44
                    radius: 14
                    color: addTap.pressed ? Theme.surfacePress : Theme.surfaceHigh
                    Text {
                        anchors.centerIn: parent
                        text: "Add to Home Screen"
                        color: Theme.text
                        font.pixelSize: 15
                    }
                    MouseArea {
                        id: addTap
                        anchors.fill: parent
                        onClicked: {
                            if (root.menuEntry)
                                Home.addToHome(root.menuEntry.id);
                            root.menuEntry = null;
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 14
                    color: dockTap.pressed ? Theme.surfacePress : Theme.surfaceHigh
                    Text {
                        anchors.centerIn: parent
                        text: Apps.isPinned(root.menuEntry) ? "Remove from Dock" : "Add to Dock"
                        color: Theme.text
                        font.pixelSize: 15
                    }
                    MouseArea {
                        id: dockTap
                        anchors.fill: parent
                        onClicked: {
                            const e = root.menuEntry;
                            if (e) {
                                if (Apps.isPinned(e))
                                    Apps.unpinEntry(e);
                                else
                                    Apps.pin(e);
                            }
                            root.menuEntry = null;
                        }
                    }
                }

                Rectangle {
                    visible: root.menuOnHome && !root.menuInFolder
                    width: parent.width
                    height: 44
                    radius: 14
                    color: rmTap.pressed ? Qt.rgba(0.4, 0.15, 0.15, 0.98) : Qt.rgba(0.25, 0.1, 0.1, 0.97)
                    Text {
                        anchors.centerIn: parent
                        text: "Remove from Home Screen"
                        color: "#ff8f8f"
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: rmTap
                        anchors.fill: parent
                        onClicked: {
                            if (root.menuEntry)
                                Home.hideIconAt(Home.indexOfIcon(root.menuEntry.id));
                            root.menuEntry = null;
                        }
                    }
                }
            }
        }
    }
}

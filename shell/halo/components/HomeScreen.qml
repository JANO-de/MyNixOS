import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Full-screen home: clock, search, app grid. Opened by UI.homeOpen (IPC, dock button, edge swipe).
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
        if (shown) {
            search.text = "";
            search.forceActiveFocus();
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

    function launch(entry) {
        entry.execute();
        UI.closeHome();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: content
        anchors.fill: parent
        color: Qt.rgba(0.04, 0.04, 0.07, 0.55)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // Tap on empty space closes the home screen.
        MouseArea {
            anchors.fill: parent
            onClicked: UI.closeHome()
        }

        Item {
            id: page
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
                cellWidth: 132
                cellHeight: 140
                width: Math.max(1, Math.floor((parent.width - 80) / cellWidth)) * cellWidth
                clip: true
                model: root.apps

                delegate: Item {
                    id: cell
                    required property var modelData

                    width: grid.cellWidth
                    height: grid.cellHeight
                    scale: tap.pressed ? 0.92 : 1
                    Behavior on scale { NumberAnimation { duration: 90 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 80
                            height: 80
                            radius: 20
                            color: Qt.rgba(1, 1, 1, 0.10)

                            Image {
                                anchors.centerIn: parent
                                width: 56
                                height: 56
                                source: Apps.iconSource(cell.modelData.icon)
                                sourceSize: Qt.size(112, 112)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                        }

                        Text {
                            width: grid.cellWidth - 16
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: cell.modelData.name
                            color: Theme.text
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        id: tap
                        anchors.fill: parent
                        onClicked: root.launch(cell.modelData)
                    }
                }
            }
        }
    }
}

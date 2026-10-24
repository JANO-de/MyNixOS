import QtQuick
import Quickshell
import qs.services

// Rounded app tile with its label. `interactive: false` lets a parent handle touches (edit mode).
// When `entry.isFolder` is set, renders a 2x2 preview of the folder's first apps instead.
Item {
    id: root

    property var entry: null
    property bool interactive: true
    signal activated

    scale: tap.pressed && interactive ? 0.92 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }

    Column {
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Home.tile
            height: Home.tile
            radius: Home.tile / 4
            color: Qt.rgba(1, 1, 1, 0.10)

            Grid {
                visible: !!(root.entry && root.entry.isFolder)
                anchors.centerIn: parent
                columns: 2
                rows: 2
                spacing: 3

                Repeater {
                    model: (root.entry && root.entry.isFolder) ? root.entry.items.slice(0, 4) : []

                    Image {
                        required property string modelData
                        width: Home.tile * 0.32
                        height: Home.tile * 0.32
                        source: Apps.iconSource((DesktopEntries.byId(modelData) || {}).icon)
                        sourceSize: Qt.size(64, 64)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }
            }

            Image {
                visible: !(root.entry && root.entry.isFolder)
                anchors.centerIn: parent
                width: Home.tile * 0.7
                height: Home.tile * 0.7
                source: root.entry ? Apps.iconSource(root.entry.icon) : ""
                sourceSize: Qt.size(128, 128)
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        Text {
            visible: Home.showLabels
            width: root.width - 16
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.entry ? root.entry.name : ""
            color: Theme.text
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: tap
        anchors.fill: parent
        enabled: root.interactive
        onClicked: root.activated()
    }
}

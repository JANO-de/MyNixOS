import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Floating dock. Reserves space in desktop mode, overlays windows in tablet mode.
PanelWindow {
    id: root

    readonly property int iconSize: Mode.tablet ? 64 : 48

    anchors.bottom: true
    margins.bottom: 10
    implicitWidth: pill.width
    implicitHeight: iconSize + 24
    color: "transparent"
    exclusionMode: Mode.tablet ? ExclusionMode.Ignore : ExclusionMode.Auto

    WlrLayershell.namespace: "halo-dock"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        id: pill
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: row.implicitWidth + 28
        height: root.iconSize + 24
        radius: Theme.radius
        color: Theme.glass
        border.color: Theme.glassStroke
        border.width: 1

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 14

            Repeater {
                model: Apps.items

                Item {
                    id: cell
                    required property var modelData

                    width: root.iconSize
                    height: root.iconSize
                    scale: area.pressed ? 0.88 : 1
                    Behavior on scale { NumberAnimation { duration: 90 } }

                    Image {
                        anchors.fill: parent
                        source: Apps.iconSource(cell.modelData.icon)
                        sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Rectangle {
                        visible: cell.modelData.windows.length > 0
                        anchors.top: parent.bottom
                        anchors.topMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 5
                        height: 5
                        radius: 3
                        color: Apps.isActive(cell.modelData) ? Theme.accent : Theme.dim
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        onClicked: Apps.activate(cell.modelData)
                    }
                }
            }
        }
    }
}

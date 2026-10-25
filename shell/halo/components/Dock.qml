import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Floating dock. Reserves space in desktop mode, overlays windows in tablet mode.
// Rises above the home screen while it is open.
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
    WlrLayershell.layer: (UI.homeOpen || UI.overviewOpen || UI.overviewDragging) ? WlrLayer.Overlay : WlrLayer.Top
    visible: UI.dockShown || pill.opacity > 0.01

    Rectangle {
        id: pill
        anchors.bottom: parent.bottom
        // Follows the finger during the bottom swipe inside an app (iPad dock reveal).
        anchors.bottomMargin: UI.dockDragging ? -(height + 40) * (1 - UI.dockPeek) : (UI.dockShown ? 0 : -(height + 40))
        opacity: UI.dockDragging ? Math.min(1, UI.dockPeek * 2) : (UI.dockShown ? 1 : 0)
        Behavior on anchors.bottomMargin { enabled: !UI.dockDragging; NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
        Behavior on opacity { enabled: !UI.dockDragging; NumberAnimation { duration: 240 } }
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

            // Apps button: desktop mode only (tablet uses the edge swipe).
            Item {
                visible: !Mode.tablet
                width: root.iconSize
                height: root.iconSize
                scale: launcherArea.pressed ? 0.88 : 1
                Behavior on scale { NumberAnimation { duration: 90 } }

                Grid {
                    anchors.centerIn: parent
                    columns: 3
                    spacing: 4

                    Repeater {
                        model: 9
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 3
                            color: Theme.text
                            opacity: 0.85
                        }
                    }
                }

                MouseArea {
                    id: launcherArea
                    anchors.fill: parent
                    onClicked: UI.toggleHome()
                }
            }

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
                        onClicked: {
                            UI.closeHome();
                            Apps.activate(cell.modelData);
                        }
                    }
                }
            }
        }
    }
}

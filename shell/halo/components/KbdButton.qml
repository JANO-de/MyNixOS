import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Shown after the keyboard was dismissed with X, so it can be reopened for the same field.
PanelWindow {
    anchors.bottom: true
    anchors.right: true
    margins.bottom: 16
    margins.right: 16
    implicitWidth: 56
    implicitHeight: 56
    color: "transparent"
    visible: Kbd.dismissed && !Kbd.visible
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-kbd-btn"
    WlrLayershell.layer: WlrLayer.Overlay

    Rectangle {
        anchors.fill: parent
        radius: 28
        color: Qt.rgba(0.13, 0.13, 0.16, 0.82)
        border.color: Theme.glassStroke
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "⌨"
            color: Theme.text
            font.pixelSize: 24
        }
        MouseArea {
            anchors.fill: parent
            onClicked: Kbd.show()
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Grabber + X above the on-screen keyboard. Drag down or tap X to hide it.
PanelWindow {
    id: root

    readonly property int travel: 140

    anchors.bottom: true
    margins.bottom: Kbd.heightFor(screen)
    implicitWidth: 260
    implicitHeight: 48 + travel
    color: "transparent"
    visible: Kbd.visible
    exclusionMode: ExclusionMode.Ignore
    // Only the pill takes touches; the rest of the window is click-through.
    mask: Region { item: pill }

    WlrLayershell.namespace: "halo-kbd"
    WlrLayershell.layer: WlrLayer.Overlay

    Rectangle {
        id: pill
        width: 240
        height: 40
        radius: 20
        x: (parent.width - width) / 2
        y: root.travel + 4 + drag.offset
        color: Qt.rgba(0.13, 0.13, 0.16, 0.82)
        border.color: Theme.glassStroke
        border.width: 1
        opacity: 1 - Math.min(0.6, drag.offset / 200)
        Behavior on y { enabled: !drag.pressed; NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: 70
            width: 50
            height: 5
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.5)
        }

        MouseArea {
            id: drag
            property real offset: 0
            property real startY: 0
            anchors.fill: parent
            anchors.rightMargin: 48
            preventStealing: true
            onPressed: mouse => startY = mapToItem(null, mouse.x, mouse.y).y
            onPositionChanged: mouse => {
                if (pressed)
                    offset = Math.max(0, Math.min(root.travel, mapToItem(null, mouse.x, mouse.y).y - startY));
            }
            onReleased: {
                if (offset > 50)
                    Kbd.hide();
                offset = 0;
            }
            onCanceled: offset = 0
        }

        // X button
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            radius: 15
            color: Qt.rgba(1, 1, 1, 0.16)

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: Theme.text
                font.pixelSize: 14
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                onClicked: Kbd.hide()
            }
        }
    }
}

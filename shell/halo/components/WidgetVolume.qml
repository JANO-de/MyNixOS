import QtQuick
import qs.services

// Volume slider (drag or tap).
Item {
    id: root
    readonly property real v: Math.max(0, Math.min(1, System.muted ? 0 : System.volume))

    Text {
        anchors.top: parent.top
        text: "Volume"
        color: Theme.dim
        font.pixelSize: 13
    }
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        text: Math.round(root.v * 100) + "%"
        color: Theme.text
        font.pixelSize: 13
    }

    Rectangle {
        id: track
        anchors.centerIn: parent
        width: parent.width
        height: Math.min(56, parent.height * 0.4)
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.14)
        clip: true

        Rectangle {
            width: Math.max(parent.height, parent.width * root.v)
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 14
            text: "\u266a"
            color: Theme.accentInk
            font.pixelSize: track.height * 0.45
        }
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            function setAt(x) { System.setVolume(Math.max(0, Math.min(1, x / width))); }
            onPressed: mouse => setAt(mouse.x)
            onPositionChanged: mouse => setAt(mouse.x)
        }
    }
}

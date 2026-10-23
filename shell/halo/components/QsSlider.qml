import QtQuick
import qs.services

// iOS-style pill slider: filled from the left, drag or tap to set.
Rectangle {
    id: root

    property real value: 0
    property string label: ""
    signal moved(real v)

    height: 56
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.14)
    clip: true

    Rectangle {
        width: Math.max(root.height, root.width * root.value)
        height: parent.height
        radius: root.radius
        color: Qt.rgba(1, 1, 1, 0.85)
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 22
        text: root.label
        color: "#1c1c1e"
        font.pixelSize: 15
        font.weight: Font.Medium
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
        onPressed: mouse => root.moved(Math.max(0, Math.min(1, mouse.x / width)))
        onPositionChanged: mouse => {
            if (pressed)
                root.moved(Math.max(0, Math.min(1, mouse.x / width)));
        }
    }
}

import QtQuick
import qs.services

// iOS-style pill slider. The fill follows the finger 1:1 (no animation while dragging),
// updates to the system are throttled to ~22 Hz, and it grows slightly while held.
Rectangle {
    id: root

    property real value: 0
    property string label: ""
    property string icon: ""
    signal moved(real v)

    property bool dragging: false
    property real local: 0
    property real pending: -1
    readonly property real shown: dragging ? local : value

    function flush() {
        if (pending >= 0) {
            moved(pending);
            pending = -1;
        }
    }

    function setFrom(x) {
        local = Math.max(0, Math.min(1, x / width));
        pending = local;
    }

    height: 60
    radius: height / 2
    color: Theme.tint(0.14)
    clip: true
    scale: dragging ? 1.025 : 1
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Timer {
        interval: 45
        repeat: true
        running: root.dragging
        onTriggered: root.flush()
    }

    Rectangle {
        width: Math.max(root.height, root.width * root.shown)
        height: parent.height
        radius: root.radius
        color: Theme.tint(0.88)
        Behavior on width {
            enabled: !root.dragging
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }

    QIcon {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 20
        size: 26
        name: root.icon
        color: "#1c1c1e"
        opacity: 0.75
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
        onPressed: mouse => {
            root.dragging = true;
            root.setFrom(mouse.x);
            root.flush();
        }
        onPositionChanged: mouse => {
            if (pressed)
                root.setFrom(mouse.x);
        }
        onReleased: {
            root.flush();
            root.dragging = false;
        }
        onCanceled: root.dragging = false
    }
}

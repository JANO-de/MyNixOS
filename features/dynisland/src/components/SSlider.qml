// Settings slider with value label. Emits moved(value) snapped to stepSize.
import QtQuick
import qs.services

Item {
    id: s
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: 0
    property string suffix: ""
    signal moved(real value)
    implicitWidth: 240; implicitHeight: 28

    readonly property real frac: (value - from) / (to - from)
    Rectangle {
        id: tr; anchors { left: parent.left; right: lbl.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        height: 6; radius: 3; color: Theme.surfaceContainerHigh
        Rectangle { width: parent.width * Math.max(0, Math.min(1, s.frac)); height: parent.height; radius: 3; color: Theme.primary }
        Rectangle { x: parent.width * Math.max(0, Math.min(1, s.frac)) - 8; y: -5; width: 16; height: 16; radius: 8; color: Theme.primary }
    }
    Text { id: lbl; anchors { right: parent.right; verticalCenter: parent.verticalCenter } width: 56
           horizontalAlignment: Text.AlignRight; color: Theme.surfaceFgDim; font.pixelSize: 13
           text: (Math.round(s.value * 100) / 100) + s.suffix }
    property real wheelAcc: 0
    MouseArea {
        anchors { fill: tr; topMargin: -10; bottomMargin: -10 }
        function set(x) {
            const f = Math.max(0, Math.min(1, x / width));
            const raw = s.from + f * (s.to - s.from);
            s.moved(Math.round(raw / s.stepSize) * s.stepSize);
        }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x) }
    }
    MouseArea {   // wheel only (clicks fall through to the drag area below); accepts the event so a parent Flickable doesn't scroll
        anchors.fill: parent; acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            s.wheelAcc += wheel.angleDelta.y / 120
            const n = Math.trunc(s.wheelAcc); wheel.accepted = true
            if (n === 0) return
            s.wheelAcc -= n
            s.moved(Math.max(s.from, Math.min(s.to, s.value + n * s.stepSize)))
        }
    }
}

// Island slider: icon + draggable track. value 0..1, emits moved(v).
import QtQuick
import qs.services

Item {
    id: s
    property real value: 0
    property string icon: ""
    signal moved(real v)
    implicitHeight: 28

    Icon { id: ic; name: s.icon; size: 18; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
    Rectangle {
        id: track
        anchors { left: ic.right; right: parent.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
        height: 8; radius: 4; color: "#33ffffff"
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, s.value)); height: parent.height; radius: 4
            color: Theme.primary
        }
    }
    MouseArea {
        anchors { fill: track; topMargin: -10; bottomMargin: -10 }
        function set(x) { s.moved(Math.max(0, Math.min(1, x / width))) }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x) }
    }
}

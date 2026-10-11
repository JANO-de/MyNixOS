// Volume / brightness feedback shown inside the island.
import QtQuick
import qs.services
import qs.components

Item {
    id: v
    property bool active: false
    anchors.fill: parent
    opacity: active ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 150 } }

    readonly property string glyph: Osd.kind === "brightness" ? "brightness_6"
        : (Osd.value <= 0 ? "volume_off" : Osd.value < 0.4 ? "volume_down" : "volume_up")

    Icon { id: ic; name: v.glyph; size: 22; anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter } }
    Rectangle {
        anchors { left: ic.right; right: pct.left; leftMargin: 12; rightMargin: 12; verticalCenter: parent.verticalCenter }
        height: 8; radius: 4; color: "#33ffffff"
        Rectangle {
            height: parent.height; radius: 4; color: Theme.primary
            width: parent.width * Math.max(0, Math.min(1, Osd.value))
            Behavior on width { NumberAnimation { duration: 80 } }
        }
    }
    Text { id: pct; anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
           text: Math.round(Osd.value * 100) + "%"; color: "white"; font.pixelSize: 13 }
}

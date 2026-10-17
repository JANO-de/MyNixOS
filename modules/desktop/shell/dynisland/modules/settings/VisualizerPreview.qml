// Mini live preview of the cava visualizer: bars react to Cava.values and
// recolor with Rainbow colors, matching the real island visualizer.
import QtQuick
import qs.config
import qs.services
import qs.components

Rectangle {
    width: parent ? parent.width : 400
    height: 70
    radius: 16; color: "black"; clip: true
    border.width: 1; border.color: Glass.outline

    Row {
        anchors.centerIn: parent; spacing: 3
        Repeater {
            model: 24
            Rectangle {
                required property int index
                readonly property real v: Config.cava.enabled ? Math.min(1, (Cava.values[index % Cava.values.length] || 0) * Config.cava.sensitivity) : 0
                width: 6; radius: 3; anchors.bottom: parent.bottom
                height: 6 + v * 48
                color: Config.cava.rainbow ? Qt.hsla((index / 24 + (Date.now() % 3000) / 3000) % 1, 0.7, 0.6, 1) : Theme.primary
                Behavior on height { NumberAnimation { duration: 80 } }
            }
        }
    }
    Text { visible: !Config.cava.enabled; anchors.centerIn: parent; text: "Visualizer disabled"; color: "#88ffffff"; font.pixelSize: 12 }
}

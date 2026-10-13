// Row of color circles. colors: ["", "#rrggbb", ...] ("" = automatic). Emits picked(color).
import QtQuick
import qs.services

Flow {
    id: s
    property var colors: []
    property string current: ""
    signal picked(string color)
    spacing: 10
    Repeater {
        model: s.colors
        Rectangle {
            required property string modelData
            readonly property bool sel: modelData === s.current
            width: 32; height: 32; radius: 16
            color: modelData === "" ? Theme.surfaceContainerHigh : modelData
            border.width: sel ? 3 : 1; border.color: sel ? Theme.surfaceFg : Theme.outline
            Icon { visible: parent.modelData === ""; anchors.centerIn: parent; name: "auto_awesome"; size: 17; color: Theme.surfaceFg }
            MouseArea { anchors.fill: parent; onClicked: s.picked(parent.modelData) }
        }
    }
}

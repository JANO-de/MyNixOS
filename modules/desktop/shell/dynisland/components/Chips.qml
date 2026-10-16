// Single-choice chips. model: [{label, value}]. Emits picked(value).
import QtQuick
import qs.services

Flow {
    id: c
    property var model: []
    property var current
    signal picked(var value)
    spacing: 8
    Repeater {
        model: c.model
        Rectangle {
            required property var modelData
            readonly property bool sel: modelData.value === c.current
            width: lbl.implicitWidth + 24; height: 30; radius: 15
            color: sel ? Theme.primary : Theme.surfaceContainerHigh
            border.width: 1; border.color: sel ? Qt.lighter(Theme.primary, 1.3) : Theme.outline
            Behavior on color { ColorAnimation { duration: 120 } }
            Text { id: lbl; anchors.centerIn: parent; text: modelData.label; font.pixelSize: 13
                   color: parent.sel ? Theme.primaryFg : Theme.surfaceFg }
            MouseArea { anchors.fill: parent; onClicked: c.picked(modelData.value) }
        }
    }
}

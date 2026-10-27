import QtQuick
import qs.common

// Segmented control (same look as the Files view switcher). model: [{label, value}]. Emits picked(value).
Rectangle {
    id: s
    property var model: []
    property var current
    signal picked(var value)

    implicitHeight: 44
    implicitWidth: row.implicitWidth + 8
    radius: 22
    color: AppTheme.card

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0
        Repeater {
            model: s.model
            Rectangle {
                required property var modelData
                readonly property bool sel: modelData.value === s.current
                width: Math.max(64, lbl.implicitWidth + 28)
                height: 38
                radius: 19
                color: sel ? AppTheme.accentSoft : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    id: lbl
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: parent.sel ? AppTheme.accent : AppTheme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: s.picked(parent.modelData.value)
                }
            }
        }
    }
}

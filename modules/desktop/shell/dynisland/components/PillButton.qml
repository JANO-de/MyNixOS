// Rounded text button (optionally with an icon). `filled` = accent color. Use `enabled: false` to grey it out.
import QtQuick
import qs.services

Rectangle {
    id: b
    property string label: ""
    property string icon: ""
    property bool filled: false
    signal clicked()
    implicitHeight: 40; implicitWidth: r.implicitWidth + 32; radius: 20
    opacity: enabled ? 1 : 0.4
    color: filled ? (ma.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)
                  : (ma.containsMouse ? Theme.surfaceContainerHigh : "transparent")
    border.width: filled ? 0 : 1; border.color: Theme.outline
    scale: ma.pressed ? 0.96 : 1
    Behavior on color { ColorAnimation { duration: 100 } }
    Behavior on scale { NumberAnimation { duration: 80 } }
    Row {
        id: r; anchors.centerIn: parent; spacing: 8
        Icon { visible: b.icon !== ""; name: b.icon; size: 18; color: b.filled ? Theme.primaryFg : Theme.surfaceFg
               anchors.verticalCenter: parent.verticalCenter }
        Text { text: b.label; font.pixelSize: 14; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter
               color: b.filled ? Theme.primaryFg : Theme.surfaceFg }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; enabled: b.enabled; onClicked: b.clicked() }
}

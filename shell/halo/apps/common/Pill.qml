import QtQuick
import qs.common

// Small round button / chip.
Rectangle {
    id: root
    property string label: ""
    property bool on: false
    property bool danger: false
    signal clicked

    implicitWidth: Math.max(44, t.implicitWidth + 28)
    implicitHeight: 44
    radius: 22
    color: on ? AppTheme.accent : AppTheme.card
    opacity: enabled ? 1 : 0.4

    Text {
        id: t
        anchors.centerIn: parent
        text: root.label
        color: root.on ? AppTheme.accentInk : (root.danger ? "#ff8a80" : AppTheme.text)
        font.pixelSize: 15
        font.weight: Font.DemiBold
    }
    MouseArea { anchors.fill: parent; onClicked: root.clicked() }
}

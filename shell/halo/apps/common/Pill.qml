import QtQuick
import qs.common

// Round button / chip with a state layer. glyph = single character icon, label = text.
Rectangle {
    id: root
    property string label: ""
    property string glyph: ""
    property string icon: ""
    property bool on: false
    property bool danger: false
    property bool flat: false
    property bool filled: false
    signal clicked
    signal pressAndHold

    readonly property color ink: filled ? AppTheme.accentInk : (on ? AppTheme.accent : (danger ? "#ff8a80" : AppTheme.text))
    implicitWidth: Math.max(44, row.implicitWidth + (label !== "" ? 28 : 0))
    implicitHeight: 44
    radius: height / 2
    color: filled ? AppTheme.accent : (on ? AppTheme.accentSoft : (ma.pressed ? AppTheme.cardHigh : (flat ? (ma.containsMouse ? AppTheme.hover : "transparent") : AppTheme.card)))
    opacity: enabled ? 1 : 0.35
    scale: ma.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Item { visible: root.icon !== ""; width: 22; height: 24; Ico { anchors.centerIn: parent; name: root.icon; color: root.ink; size: 22 } }
        Text { visible: root.glyph !== ""; text: root.glyph; color: root.ink; font.pixelSize: 20; height: 24; verticalAlignment: Text.AlignVCenter }
        Text { visible: root.label !== ""; text: root.label; color: root.ink; font.pixelSize: 15; font.weight: Font.DemiBold; height: 24; verticalAlignment: Text.AlignVCenter }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
        onPressAndHold: root.pressAndHold()
    }
}

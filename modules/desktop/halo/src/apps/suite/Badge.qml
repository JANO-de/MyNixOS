import QtQuick
import qs.common

// Round accent badge: line icon or one letter (contact initial, list lead).
Rectangle {
    id: b
    property string icon: ""
    property string letter: ""
    property real diameter: 40
    width: diameter
    height: diameter
    radius: diameter / 2
    color: AppTheme.accentSoft

    Ico {
        visible: b.icon !== ""
        anchors.centerIn: parent
        name: b.icon
        size: b.diameter * 0.55
        color: AppTheme.accent
    }
    Text {
        visible: b.icon === "" && b.letter !== ""
        anchors.centerIn: parent
        text: b.letter
        color: AppTheme.accent
        font.pixelSize: b.diameter * 0.5
        font.weight: Font.Medium
    }
}

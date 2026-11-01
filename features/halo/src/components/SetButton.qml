import QtQuick
import qs.services

// Settings: small pill button (trailing in rows, or on its own).
Rectangle {
    id: root

    property string text: ""
    property bool accent: false
    property bool danger: false
    signal clicked

    width: label.implicitWidth + 28
    height: 36
    radius: 18
    color: danger ? "#ff5f5f" : (accent ? Theme.accent : Theme.tint(0.16))
    scale: tap.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.danger ? "#2b0a0a" : (root.accent ? Theme.accentInk : Theme.text)
        font.pixelSize: 14
        font.weight: Font.DemiBold
    }
    MouseArea {
        id: tap
        anchors.fill: parent
        anchors.margins: -6
        onClicked: root.clicked()
    }
}

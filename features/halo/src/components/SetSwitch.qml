import QtQuick
import qs.services

// Settings: iOS-style switch. Emits toggled(); the owner flips the state it is bound to.
Rectangle {
    id: root

    property bool checked: false
    signal toggled

    width: 58
    height: 34
    radius: 17
    color: checked ? Theme.accent : Theme.tint(0.22)
    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
        y: 3
        x: root.checked ? parent.width - width - 3 : 3
        width: 28
        height: 28
        radius: 14
        color: root.checked ? Theme.accentInk : "#ffffff"
        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -8
        onClicked: root.toggled()
    }
}

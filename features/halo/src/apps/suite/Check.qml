import QtQuick
import qs.common

// Round check mark (reminders). The owner flips the state it is bound to on toggled().
Rectangle {
    id: root
    property bool checked: false
    signal toggled

    width: 30
    height: 30
    radius: 15
    color: checked ? AppTheme.accent : "transparent"
    border.width: 2
    border.color: checked ? AppTheme.accent : AppTheme.dim
    Behavior on color { ColorAnimation { duration: 120 } }

    Ico {
        visible: root.checked
        anchors.centerIn: parent
        name: "check"
        size: 18
        color: AppTheme.accentInk
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -8
        onClicked: root.toggled()
    }
}

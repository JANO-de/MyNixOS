// Settings switch. Usage: Toggle { checked: Config.x.y; onToggled: Config.x.y = !Config.x.y }
import QtQuick
import qs.services

Rectangle {
    id: t
    property bool checked: false
    signal toggled()
    implicitWidth: 46; implicitHeight: 26; radius: 13
    color: checked ? Theme.primary : Theme.surfaceContainerHigh
    border.width: checked ? 0 : 1; border.color: Theme.outline
    Behavior on color { ColorAnimation { duration: 140 } }
    Rectangle {
        width: 18; height: 18; radius: 9; y: 4
        x: t.checked ? parent.width - width - 4 : 4
        color: t.checked ? Theme.primaryFg : Theme.outline
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
    MouseArea { anchors.fill: parent; onClicked: t.toggled() }
}

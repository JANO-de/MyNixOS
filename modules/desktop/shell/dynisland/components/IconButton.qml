// Round icon button. `active` paints it with the theme accent.
import QtQuick
import qs.services

Rectangle {
    id: b
    property string icon: ""
    property bool active: false
    property int iconSize: 20
    property int diameter: 40
    signal clicked()

    implicitWidth: diameter; implicitHeight: diameter; radius: diameter / 2
    color: active ? Theme.primary : (ma.containsMouse ? "#3affffff" : "#22ffffff")
    scale: ma.pressed ? 0.92 : 1
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 90 } }

    Icon { anchors.centerIn: parent; name: b.icon; size: b.iconSize; color: b.active ? Theme.onPrimary : "white" }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: b.clicked() }
}

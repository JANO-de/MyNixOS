import QtQuick
import qs.services

// Quick-settings toggle tile.
Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool active: false
    signal clicked

    height: 84
    radius: 22
    color: active ? Theme.accent : Qt.rgba(1, 1, 1, 0.14)
    scale: area.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }
    Behavior on color { ColorAnimation { duration: 120 } }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 12
        spacing: 3

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.title
            color: root.active ? "#0b1b33" : Theme.text
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.subtitle
            color: root.active ? "#2a3f5f" : Theme.dim
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        onClicked: root.clicked()
    }
}

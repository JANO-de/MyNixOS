import QtQuick
import qs.services

// Settings: radio list. `options` = strings, `current` = selected index; picked(i) when tapped.
Column {
    id: root

    property var options: []
    property int current: 0
    signal picked(int index)

    width: parent ? parent.width : 600
    spacing: 3

    Repeater {
        model: root.options

        Rectangle {
            id: row
            required property int index
            required property string modelData

            width: root.width
            height: 56
            radius: 22
            color: tap.pressed ? Theme.surfacePress : Theme.tint(0.07)
            Behavior on color { ColorAnimation { duration: 90 } }

            Rectangle {
                x: 20
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                radius: 12
                color: "transparent"
                border.width: 2
                border.color: row.index === root.current ? Theme.accent : Theme.dim

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    radius: 6
                    color: Theme.accent
                    visible: row.index === root.current
                }
            }
            Text {
                x: 64
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData
                color: Theme.text
                font.pixelSize: 17
                elide: Text.ElideRight
            }
            MouseArea {
                id: tap
                anchors.fill: parent
                onClicked: root.picked(row.index)
            }
        }
    }
}

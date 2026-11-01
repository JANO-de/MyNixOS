import QtQuick
import qs.services

// Settings: a row of pill choices. `options` is a list of strings, `current` the selected index.
Flow {
    id: root

    property var options: []
    property int current: 0
    signal picked(int index)

    width: parent ? parent.width : 600
    spacing: 8

    Repeater {
        model: root.options

        Rectangle {
            required property int index
            required property string modelData

            width: label.implicitWidth + 32
            height: 40
            radius: 20
            color: index === root.current ? Theme.accent : Theme.tint(0.14)
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                id: label
                anchors.centerIn: parent
                text: parent.modelData
                color: parent.index === root.current ? Theme.accentInk : Theme.text
                font.pixelSize: 15
                font.weight: Font.Medium
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.picked(parent.index)
            }
        }
    }
}

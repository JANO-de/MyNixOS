import QtQuick
import Quickshell
import qs.services

// Analog clock.
Item {
    id: root

    readonly property real s: Math.min(width, height)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.centerIn: parent
        width: root.s
        height: root.s
        radius: root.s / 2
        color: Qt.rgba(1, 1, 1, 0.07)
    }

    Repeater {
        model: 12
        Item {
            required property int index
            anchors.centerIn: parent
            width: 2
            height: root.s - 14
            rotation: index * 30
            Rectangle {
                width: 2
                height: index % 3 === 0 ? 11 : 5
                radius: 1
                color: index % 3 === 0 ? Theme.text : Theme.dim
            }
        }
    }

    // Hour hand
    Item {
        anchors.centerIn: parent
        width: 6
        height: root.s * 0.5
        rotation: ((clock.date.getHours() % 12) + clock.date.getMinutes() / 60) * 30
        Rectangle {
            width: 6
            height: root.s * 0.25
            radius: 3
            color: Theme.text
        }
    }

    // Minute hand
    Item {
        anchors.centerIn: parent
        width: 4
        height: root.s * 0.74
        rotation: clock.date.getMinutes() * 6
        Rectangle {
            width: 4
            height: root.s * 0.37
            radius: 2
            color: Theme.text
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 10
        height: 10
        radius: 5
        color: Theme.accent
    }
}

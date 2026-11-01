import QtQuick
import qs.common

// Analog clock face (same design as the shell's WidgetClock) with a seconds hand in the accent colour.
Item {
    id: root
    property date time: new Date()
    readonly property real s: Math.min(width, height)

    Rectangle {
        anchors.centerIn: parent
        width: root.s
        height: root.s
        radius: root.s / 2
        color: AppTheme.card
    }
    Repeater {
        model: 12
        Item {
            required property int index
            anchors.centerIn: parent
            width: 2
            height: root.s - 20
            rotation: index * 30
            Rectangle {
                width: 2
                height: index % 3 === 0 ? 14 : 7
                radius: 1
                color: index % 3 === 0 ? AppTheme.text : AppTheme.dim
            }
        }
    }
    Item {   // hour hand
        anchors.centerIn: parent
        width: 7
        height: root.s * 0.5
        rotation: ((root.time.getHours() % 12) + root.time.getMinutes() / 60) * 30
        Rectangle { width: 7; height: root.s * 0.25; radius: 3.5; color: AppTheme.text }
    }
    Item {   // minute hand
        anchors.centerIn: parent
        width: 5
        height: root.s * 0.74
        rotation: root.time.getMinutes() * 6 + root.time.getSeconds() / 10
        Rectangle { width: 5; height: root.s * 0.37; radius: 2.5; color: AppTheme.text }
    }
    Item {   // seconds hand
        anchors.centerIn: parent
        width: 2
        height: root.s * 0.8
        rotation: root.time.getSeconds() * 6
        Rectangle { width: 2; height: root.s * 0.4; radius: 1; color: AppTheme.accent }
    }
    Rectangle {
        anchors.centerIn: parent
        width: 12
        height: 12
        radius: 6
        color: AppTheme.accent
    }
}

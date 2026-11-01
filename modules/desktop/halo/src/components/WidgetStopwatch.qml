import QtQuick
import qs.services

// Stopwatch (state in WidgetData).
Item {
    id: root
    property double tick: 0
    readonly property real ms: { root.tick; return WidgetData.swElapsed(); }
    readonly property real s: Math.min(width * 0.4, height)

    function two(n) { return (n < 10 ? "0" : "") + n; }

    Timer {
        interval: 50
        repeat: true
        running: WidgetData.swRun
        onTriggered: root.tick = Date.now()
    }

    Text {
        anchors.top: parent.top
        text: "Stopwatch"
        color: Theme.dim
        font.pixelSize: 13
    }
    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.s * 0.06
        text: root.two(Math.floor(root.ms / 60000)) + ":" + root.two(Math.floor(root.ms / 1000) % 60) + "." + root.two(Math.floor(root.ms / 10) % 100)
        color: Theme.text
        font.pixelSize: Math.max(18, root.s * 0.3)
        font.weight: Font.Light
    }
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        Rectangle {
            width: 76
            height: 32
            radius: 16
            color: WidgetData.swRun ? Qt.rgba(1, 1, 1, 0.16) : Theme.accent
            Text {
                anchors.centerIn: parent
                text: WidgetData.swRun ? "Stop" : "Start"
                color: WidgetData.swRun ? Theme.text : Theme.accentInk
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            MouseArea { anchors.fill: parent; onClicked: WidgetData.swToggle() }
        }
        Rectangle {
            width: 76
            height: 32
            radius: 16
            color: Qt.rgba(1, 1, 1, 0.16)
            Text {
                anchors.centerIn: parent
                text: "Reset"
                color: Theme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            MouseArea { anchors.fill: parent; onClicked: WidgetData.swReset() }
        }
    }
}

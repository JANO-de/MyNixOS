import QtQuick
import qs.services

// Countdown timer (state in WidgetData); notifies when it ends.
Item {
    id: root
    property double tick: 0
    readonly property real remain: { root.tick; return WidgetData.tmRemaining(); }
    readonly property real s: Math.min(width * 0.4, height)

    function two(n) { return (n < 10 ? "0" : "") + n; }

    Timer {
        interval: 250
        repeat: true
        running: WidgetData.tmRun
        onTriggered: root.tick = Date.now()
    }

    Text {
        anchors.top: parent.top
        text: "Timer"
        color: Theme.dim
        font.pixelSize: 13
    }
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        spacing: 6
        visible: root.width > 180

        Repeater {
            model: [60, 300, 600, 1500]

            Rectangle {
                required property int modelData
                width: 38
                height: 24
                radius: 12
                color: WidgetData.tmDur === modelData ? Theme.accent : Qt.rgba(1, 1, 1, 0.14)
                Text {
                    anchors.centerIn: parent
                    text: parent.modelData / 60
                    color: WidgetData.tmDur === parent.modelData ? Theme.accentInk : Theme.text
                    font.pixelSize: 12
                }
                MouseArea { anchors.fill: parent; onClicked: WidgetData.tmSet(parent.modelData) }
            }
        }
    }
    Text {
        anchors.centerIn: parent
        text: root.two(Math.floor(root.remain / 60)) + ":" + root.two(Math.floor(root.remain) % 60)
        color: root.remain <= 0 ? "#ff6b6b" : Theme.text
        font.pixelSize: Math.max(18, root.s * 0.34)
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
            color: WidgetData.tmRun ? Qt.rgba(1, 1, 1, 0.16) : Theme.accent
            Text {
                anchors.centerIn: parent
                text: WidgetData.tmRun ? "Pause" : "Start"
                color: WidgetData.tmRun ? Theme.text : Theme.accentInk
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (WidgetData.tmRun)
                        WidgetData.tmPause();
                    else
                        WidgetData.tmStart();
                }
            }
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
            MouseArea { anchors.fill: parent; onClicked: WidgetData.tmSet(WidgetData.tmDur) }
        }
    }
}

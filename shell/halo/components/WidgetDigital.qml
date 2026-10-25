import QtQuick
import Quickshell
import qs.services

// Digital clock + date.
Item {
    id: root
    readonly property real s: Math.min(width * 0.45, height)

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.s * 0.08
        text: Qt.formatTime(clock.date, "hh:mm")
        color: Theme.text
        font.pixelSize: root.s * 0.55
        font.weight: Font.Light
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: Qt.formatDate(clock.date, "dddd, d MMMM")
        color: Theme.dim
        font.pixelSize: Math.max(11, root.s * 0.12)
    }
}

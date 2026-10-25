import QtQuick
import Quickshell
import qs.services

// Big day number.
Item {
    id: root
    readonly property real s: Math.min(width, height)

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Text {
        anchors.top: parent.top
        text: Qt.formatDate(clock.date, "dddd").toUpperCase()
        color: Theme.accent
        font.pixelSize: Math.max(11, root.s * 0.1)
        font.weight: Font.DemiBold
    }
    Text {
        anchors.centerIn: parent
        text: Qt.formatDate(clock.date, "d")
        color: Theme.text
        font.pixelSize: root.s * 0.5
        font.weight: Font.Light
    }
    Text {
        anchors.bottom: parent.bottom
        text: Qt.formatDate(clock.date, "MMMM yyyy")
        color: Theme.dim
        font.pixelSize: Math.max(11, root.s * 0.09)
    }
}

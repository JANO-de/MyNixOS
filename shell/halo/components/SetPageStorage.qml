import QtQuick
import qs.services

// Settings > Storage: disks and memory.
Column {
    id: page

    readonly property var root: Info.disk("root")
    readonly property var home: Info.disk("home")
    readonly property real memTotal: parseFloat(Info.kv["memtotal"] || "0")
    readonly property real memAvail: parseFloat(Info.kv["memavail"] || "0")

    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: Info.refresh()

    component Meter: Rectangle {
        property string label: ""
        property real used: 0
        property real total: 0

        width: parent ? parent.width : 600
        height: 92
        radius: 22
        color: Qt.rgba(1, 1, 1, 0.07)

        Text {
            x: 24
            y: 16
            text: label
            color: Theme.text
            font.pixelSize: 17
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 24
            y: 18
            text: total > 0 ? Info.gb(used) + " of " + Info.gb(total) : "-"
            color: Theme.dim
            font.pixelSize: 14
        }
        Rectangle {
            x: 24
            y: 54
            width: parent.width - 48
            height: 10
            radius: 5
            color: Qt.rgba(1, 1, 1, 0.14)

            Rectangle {
                width: total > 0 ? parent.width * Math.min(1, used / total) : 0
                height: parent.height
                radius: 5
                color: total > 0 && used / total > 0.9 ? "#ff5f5f" : Theme.accent
            }
        }
    }

    SetGroup {
        title: "Disks"
        Meter { label: "System (/)"; used: page.root.used; total: page.root.size }
        Meter { label: "Home"; used: page.home.used; total: page.home.size }
    }

    SetGroup {
        title: "Memory"
        Meter { label: "RAM in use"; used: page.memTotal - page.memAvail; total: page.memTotal }
    }
}

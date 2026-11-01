import QtQuick
import qs.services

// CPU / memory / disk usage.
Item {
    id: root

    Component.onCompleted: WidgetData.use("sys", 1)
    Component.onDestruction: WidgetData.use("sys", -1)

    readonly property var rows: [
        { n: "CPU", v: WidgetData.cpu, t: Math.round(WidgetData.cpu * 100) + "%" },
        { n: "RAM", v: WidgetData.mem, t: WidgetData.gb(WidgetData.memUsed) },
        { n: "Disk", v: WidgetData.disk, t: Math.round(WidgetData.disk * 100) + "%" }
    ]

    Text {
        id: head
        anchors.top: parent.top
        text: "System"
        color: Theme.dim
        font.pixelSize: 13
    }

    Column {
        anchors.top: head.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Math.max(4, (root.height - 24 - 3 * 34) / 3)

        Repeater {
            model: root.rows

            Item {
                id: r
                required property var modelData
                width: root.width
                height: 34

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: r.modelData.n
                    color: Theme.text
                    font.pixelSize: 13
                }
                Text {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: r.modelData.t
                    color: Theme.dim
                    font.pixelSize: 13
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 8
                    radius: 4
                    color: Qt.rgba(1, 1, 1, 0.14)
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, r.modelData.v))
                        height: parent.height
                        radius: 4
                        color: r.modelData.v > 0.9 ? "#ff6b6b" : Theme.accent
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}

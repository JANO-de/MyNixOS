import QtQuick
import Quickshell
import qs.services

// Month view, weeks start on Monday.
Item {
    id: root

    readonly property var now: clock.date
    readonly property int offset: (new Date(now.getFullYear(), now.getMonth(), 1).getDay() + 6) % 7
    readonly property int daysIn: new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
    readonly property real cs: width / 7

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    Text {
        id: title
        text: Qt.formatDate(root.now, "MMMM")
        color: Theme.accent
        font.pixelSize: Math.max(12, root.cs * 0.62)
        font.weight: Font.DemiBold
    }

    Grid {
        anchors.top: title.bottom
        anchors.topMargin: 4
        columns: 7

        Repeater {
            model: 7
            Item {
                required property int index
                width: root.cs
                height: root.cs * 0.8
                Text {
                    anchors.centerIn: parent
                    text: Qt.locale().dayName((index + 1) % 7, Locale.NarrowFormat)
                    color: Theme.dim
                    font.pixelSize: Math.max(9, root.cs * 0.4)
                }
            }
        }

        Repeater {
            model: 42
            Item {
                required property int index
                readonly property int day: index - root.offset + 1
                readonly property bool valid: day >= 1 && day <= root.daysIn
                readonly property bool today: valid && day === root.now.getDate()
                width: root.cs
                height: root.cs * 0.8

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    radius: width / 2
                    color: Theme.accent
                    visible: parent.today
                }
                Text {
                    anchors.centerIn: parent
                    visible: parent.valid
                    text: parent.day
                    color: parent.today ? "#0b1b33" : Theme.text
                    font.pixelSize: Math.max(9, root.cs * 0.42)
                }
            }
        }
    }
}

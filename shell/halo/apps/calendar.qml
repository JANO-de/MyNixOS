import QtQuick
import qs.common

ShellRoot {
    AppWindow {
        id: win

        title: "Calendar"
        implicitWidth: 520
        implicitHeight: 620

        property var now: new Date()
        Timer { interval: 60000; repeat: true; running: true; onTriggered: win.now = new Date() }

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16
            Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(win.now, "MMMM yyyy"); color: AppTheme.text; font.pixelSize: 28; font.weight: Font.DemiBold }
            Grid {
                columns: 7
                spacing: 6
                width: parent.width
                Repeater {
                    model: 42
                    Rectangle {
                        required property int index
                        readonly property int day: index - new Date(win.now.getFullYear(), win.now.getMonth(), 1).getDay() + 1
                        readonly property bool inMonth: day > 0 && day <= new Date(win.now.getFullYear(), win.now.getMonth() + 1, 0).getDate()
                        readonly property bool today: inMonth && day === win.now.getDate()
                        width: (parent.width - 36) / 7
                        height: (parent.width - 36) / 7
                        radius: 12
                        color: today ? AppTheme.accent : (inMonth ? AppTheme.card : "transparent")
                        Text {
                            anchors.centerIn: parent
                            text: inMonth ? day : ""
                            color: today ? AppTheme.accentInk : AppTheme.text
                            font.pixelSize: 18
                        }
                    }
                }
            }
        }
    }
}

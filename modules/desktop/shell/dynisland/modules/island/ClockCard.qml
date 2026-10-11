// Expanded view, center column: big time, date, week strip, weather.
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

ColumnLayout {
    id: c
    spacing: 4

    Text { Layout.alignment: Qt.AlignHCenter; text: Clock.time; color: "white"; font.pixelSize: 40; font.weight: Font.Bold }
    Text { Layout.alignment: Qt.AlignHCenter; text: Clock.dateLong; color: "#bbffffff"; font.pixelSize: 13 }

    // Week strip, today highlighted (Mon..Sun around the current date)
    Row {
        Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8; spacing: 6
        Repeater {
            model: 7
            Rectangle {
                readonly property date d: {
                    const t = new Date(Clock.date);
                    const off = (t.getDay() + 6) % 7;            // Monday = 0
                    return new Date(t.getFullYear(), t.getMonth(), t.getDate() - off + index);
                }
                readonly property bool today: d.getDate() === Clock.date.getDate() && d.getMonth() === Clock.date.getMonth()
                width: Math.max(20, Math.min(30, (c.width - 36) / 7)); height: 38; radius: 15; color: today ? Theme.primary : "transparent"   // shrinks to fit the column
                Column {
                    anchors.centerIn: parent; spacing: 1
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(parent.parent.d, "ddd").substring(0, 2)
                           font.pixelSize: 9; color: parent.parent.today ? Theme.primaryFg : "#88ffffff" }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.parent.d.getDate()
                           font.pixelSize: 13; font.weight: Font.DemiBold; color: parent.parent.today ? Theme.primaryFg : "white" }
                }
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 6; spacing: 6; visible: Config.island.showWeather
        Icon { name: Weather.icon; size: 20; color: Theme.primary }
        Text { text: Weather.temp + "  " + Weather.cond; color: "#ddffffff"; font.pixelSize: 13; elide: Text.ElideRight }
    }

    // tray icons (hidden when the tray is empty)
    TrayStrip { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4 }
}

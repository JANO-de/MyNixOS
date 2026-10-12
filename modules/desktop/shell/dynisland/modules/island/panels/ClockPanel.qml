// Stopwatch + countdown timer (state lives in services/Clocks.qml so it keeps running when closed).
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

PanelFrame {
    id: p
    title: tab === 0 ? "Stopwatch" : "Timer"; icon: tab === 0 ? "timer" : "hourglass_empty"
    property int tab: Clocks.tRunning && !Clocks.swRunning ? 1 : 0

    Column {
        anchors.fill: parent; spacing: 12
        // tabs
        Row {
            spacing: 8
            Repeater {
                model: ["Stopwatch", "Timer"]
                Rectangle {
                    required property string modelData
                    required property int index
                    width: 96; height: 30; radius: 15
                    color: p.tab === index ? Theme.primary : "#18ffffff"
                    Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 13
                           color: p.tab === index ? Theme.primaryFg : "white" }
                    MouseArea { anchors.fill: parent; onClicked: p.tab = index }
                }
            }
        }

        // big readout
        Text {
            width: parent.width; horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 52; font.weight: Font.Bold; font.family: "monospace"; color: "white"
            text: p.tab === 0 ? Clocks.fmt(Clocks.swMs, true) : Clocks.fmt(Clocks.tLeft, false)
        }

        // ---- stopwatch controls
        Row {
            visible: p.tab === 0; anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
            PillButton { label: "Lap"; icon: "flag"; enabled: Clocks.swMs > 0; onClicked: Clocks.swLap() }
            PillButton { label: Clocks.swRunning ? "Pause" : "Start"; icon: Clocks.swRunning ? "pause" : "play_arrow"; filled: true
                         onClicked: Clocks.swToggle() }
            PillButton { label: "Reset"; icon: "restart_alt"; enabled: Clocks.swMs > 0; onClicked: Clocks.swReset() }
        }
        Flickable {
            visible: p.tab === 0; width: parent.width; height: 70; clip: true
            contentHeight: lapCol.height; boundsBehavior: Flickable.StopAtBounds
            Column {
                id: lapCol; width: parent.width; spacing: 2
                Repeater {
                    model: Clocks.laps
                    Text { required property real modelData; required property int index
                           color: "#bbffffff"; font.pixelSize: 12; font.family: "monospace"
                           text: "Lap " + (Clocks.laps.length - index) + "   " + Clocks.fmt(modelData, true) }
                }
            }
        }

        // ---- timer controls
        Row {
            visible: p.tab === 1; anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
            Repeater {
                model: [1, 5, 10, 15, 30, 60]
                Rectangle {
                    required property int modelData
                    width: 48; height: 28; radius: 14
                    color: Clocks.tDuration === modelData * 60000 ? Theme.primary : "#18ffffff"
                    Text { anchors.centerIn: parent; text: modelData + "m"; font.pixelSize: 12
                           color: Clocks.tDuration === modelData * 60000 ? Theme.primaryFg : "white" }
                    MouseArea { anchors.fill: parent; onClicked: Clocks.tSet(modelData * 60000) }
                }
            }
        }
        Row {
            visible: p.tab === 1; anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
            PillButton { label: "-1m"; enabled: !Clocks.tRunning; onClicked: Clocks.tSet(Clocks.tDuration - 60000) }
            PillButton { label: Clocks.tRunning ? "Pause" : "Start"; icon: Clocks.tRunning ? "pause" : "play_arrow"; filled: true
                         onClicked: Clocks.tToggle() }
            PillButton { label: "+1m"; enabled: !Clocks.tRunning; onClicked: Clocks.tSet(Clocks.tDuration + 60000) }
            PillButton { label: "Reset"; icon: "restart_alt"; onClicked: Clocks.tReset() }
        }
        Rectangle {   // timer progress
            visible: p.tab === 1; width: parent.width; height: 6; radius: 3; color: "#22ffffff"
            Rectangle { height: parent.height; radius: 3; color: Theme.primary
                        width: parent.width * (Clocks.tDuration > 0 ? Clocks.tLeft / Clocks.tDuration : 0) }
        }
    }
}

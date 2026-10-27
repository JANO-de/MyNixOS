import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.suite

ShellRoot {
    AppWindow {
        id: win

        title: "Clock"
        implicitWidth: 560
        implicitHeight: 760

        property string tab: "clock"
        readonly property string alarmSh: String(Qt.resolvedUrl("suite/alarm.sh")).replace("file://", "")
        function pad(n) { return (n < 10 ? "0" : "") + n; }
        function run(args) { Quickshell.execDetached(args); }

        SystemClock { id: clk; precision: SystemClock.Seconds }
        JsonStore { id: zoneStore; name: "clock-zones"; fallback: ["UTC", "America/New_York", "Europe/London", "Asia/Tokyo"]; onLoaded: win.refreshZones() }
        JsonStore { id: alarmStore; name: "clock-alarms"; fallback: [] }

        property var zoneTimes: []
        function refreshZones() {
            zp.command = ["sh", "-c", "for z in \"$@\"; do TZ=$z date '+%a %H:%M'; done", "sh"].concat(zoneStore.value);
            zp.running = false;
            zp.running = true;
        }
        Process {
            id: zp
            stdout: StdioCollector { onStreamFinished: win.zoneTimes = text.trim().split("\n") }
        }
        Timer { interval: 30000; repeat: true; running: win.tab === "clock"; onTriggered: win.refreshZones() }

        property int tmSecs: 300
        property double tmEnd: 0
        readonly property bool tmOn: tmEnd > 0
        property double now: Date.now()
        Timer {
            interval: 250
            repeat: true
            running: win.tmOn || win.swOn
            onTriggered: {
                win.now = Date.now();
                if (win.tmOn && win.now >= win.tmEnd)
                    win.tmEnd = 0;
            }
        }
        function tmStart() {
            tmEnd = Date.now() + tmSecs * 1000;
            run(["systemd-run", "--user", "--unit=halo-timer", "--on-active=" + tmSecs + "s", "/run/current-system/sw/bin/notify-send", "-u", "critical", "-i", "appointment-soon", "Halo", "Timer finished"]);
        }
        function tmStop() {
            tmEnd = 0;
            run(["systemctl", "--user", "stop", "halo-timer.timer", "halo-timer.service"]);
        }
        function fmtSecs(s) { s = Math.max(0, Math.round(s)); return pad(Math.floor(s / 3600)) + ":" + pad(Math.floor(s / 60) % 60) + ":" + pad(s % 60); }

        property double swStart: 0
        property double swAcc: 0
        property bool swOn: false
        property var laps: []
        readonly property double swMs: swAcc + (swOn ? now - swStart : 0)
        function swToggle() {
            if (swOn) {
                swAcc += Date.now() - swStart;
                swOn = false;
            } else {
                swStart = Date.now();
                now = swStart;
                swOn = true;
            }
        }
        function swReset() { swOn = false; swAcc = 0; laps = []; }
        function fmtMs(ms) { return pad(Math.floor(ms / 60000)) + ":" + pad(Math.floor(ms / 1000) % 60) + "." + pad(Math.floor(ms / 10) % 100); }

        property int ah: 7
        property int am: 0
        function addAlarm() {
            const id = String(Date.now());
            const t = pad(ah) + ":" + pad(am);
            alarmStore.value = alarmStore.value.concat([{ id: id, time: t, label: "Alarm", on: true }]);
            alarmStore.save();
            run(["sh", alarmSh, "set", id, t, "Alarm"]);
        }
        function toggleAlarm(i) {
            const l = alarmStore.value.slice();
            l[i] = Object.assign({}, l[i], { on: !l[i].on });
            alarmStore.value = l;
            alarmStore.save();
            if (l[i].on)
                run(["sh", alarmSh, "set", l[i].id, l[i].time, l[i].label]);
            else
                run(["sh", alarmSh, "clear", l[i].id]);
        }
        function delAlarm(i) {
            run(["sh", alarmSh, "clear", alarmStore.value[i].id]);
            alarmStore.value = alarmStore.value.filter((a, j) => j !== i);
            alarmStore.save();
        }

        Row {
            id: tabs
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: 16
            spacing: 8
            Repeater {
                model: [{ k: "clock", l: "Clock" }, { k: "alarm", l: "Alarms" }, { k: "timer", l: "Timer" }, { k: "sw", l: "Stopwatch" }]
                Pill {
                    required property var modelData
                    label: modelData.l
                    on: win.tab === modelData.k
                    onClicked: win.tab = modelData.k
                }
            }
        }

        Item {
            anchors.top: tabs.bottom
            anchors.topMargin: 16
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16

            Column {
                visible: win.tab === "clock"
                anchors.fill: parent
                spacing: 12
                Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Qt.formatTime(clk.date, "HH:mm:ss"); color: AppTheme.text; font.pixelSize: 72; font.weight: Font.Light }
                Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(clk.date, "dddd, d MMMM yyyy"); color: AppTheme.dim; font.pixelSize: 18; bottomPadding: 12 }
                Repeater {
                    model: zoneStore.value
                    Rectangle {
                        required property string modelData
                        required property int index
                        width: parent.width
                        height: 60
                        radius: 24
                        color: AppTheme.card
                        Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: modelData.replace(/_/g, " "); color: AppTheme.text; font.pixelSize: 18 }
                        Text { anchors.right: parent.right; anchors.rightMargin: 64; anchors.verticalCenter: parent.verticalCenter; text: win.zoneTimes[index] || ""; color: AppTheme.text; font.pixelSize: 22 }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: "✕"
                            color: AppTheme.dim
                            font.pixelSize: 16
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -12
                                onClicked: {
                                    zoneStore.value = zoneStore.value.filter((z, j) => j !== index);
                                    zoneStore.save();
                                    win.refreshZones();
                                }
                            }
                        }
                    }
                }
                Field {
                    id: zf
                    width: parent.width
                    placeholder: "Add a zone, e.g. Europe/Madrid (Enter)"
                    onAccepted: {
                        if (text.trim() !== "") {
                            zoneStore.value = zoneStore.value.concat([text.trim()]);
                            zoneStore.save();
                            text = "";
                            win.refreshZones();
                        }
                    }
                }
            }

            Column {
                visible: win.tab === "alarm"
                anchors.fill: parent
                spacing: 12
                Center {
                    Row {
                        spacing: 10
                        Pill { glyph: "−"; onClicked: win.ah = (win.ah + 23) % 24 }
                        Text { width: 52; horizontalAlignment: Text.AlignHCenter; text: win.pad(win.ah); color: AppTheme.text; font.pixelSize: 44; anchors.verticalCenter: parent.verticalCenter }
                        Pill { glyph: "+"; onClicked: win.ah = (win.ah + 1) % 24 }
                        Text { text: ":"; color: AppTheme.text; font.pixelSize: 44; anchors.verticalCenter: parent.verticalCenter }
                        Pill { glyph: "−"; onClicked: win.am = (win.am + 55) % 60 }
                        Text { width: 52; horizontalAlignment: Text.AlignHCenter; text: win.pad(win.am); color: AppTheme.text; font.pixelSize: 44; anchors.verticalCenter: parent.verticalCenter }
                        Pill { glyph: "+"; onClicked: win.am = (win.am + 5) % 60 }
                    }
                }
                Center {
                    Pill { label: "Add alarm"; filled: true; onClicked: win.addAlarm() }
                }
                Repeater {
                    model: alarmStore.value
                    Rectangle {
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 64
                        radius: 24
                        color: AppTheme.card
                        Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: modelData.time; color: modelData.on ? AppTheme.text : AppTheme.dim; font.pixelSize: 30 }
                        Text { x: 130; anchors.verticalCenter: parent.verticalCenter; text: "every day"; color: AppTheme.dim; font.pixelSize: 14 }
                        Pill { anchors.right: parent.right; anchors.rightMargin: 64; anchors.verticalCenter: parent.verticalCenter; label: modelData.on ? "On" : "Off"; on: modelData.on; onClicked: win.toggleAlarm(index) }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: "✕"
                            color: AppTheme.dim
                            font.pixelSize: 16
                            MouseArea { anchors.fill: parent; anchors.margins: -12; onClicked: win.delAlarm(index) }
                        }
                    }
                }
            }

            Column {
                visible: win.tab === "timer"
                anchors.fill: parent
                spacing: 18
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 30
                    text: win.fmtSecs(win.tmOn ? (win.tmEnd - win.now) / 1000 : win.tmSecs)
                    color: AppTheme.text
                    font.pixelSize: 72
                    font.weight: Font.Light
                }
                Center {
                    Row {
                        spacing: 8
                        visible: !win.tmOn
                        Repeater {
                            model: [60, 300, 600, 900, 1800]
                            Pill {
                                required property int modelData
                                label: modelData / 60 + " min"
                                on: win.tmSecs === modelData
                                onClicked: win.tmSecs = modelData
                            }
                        }
                    }
                }
                Center {
                    Row {
                        spacing: 8
                        visible: !win.tmOn
                        Pill { label: "−1 min"; onClicked: win.tmSecs = Math.max(60, win.tmSecs - 60) }
                        Pill { label: "+1 min"; onClicked: win.tmSecs += 60 }
                    }
                }
                Center {
                    Pill {
                        label: win.tmOn ? "Cancel" : "Start"
                        filled: !win.tmOn
                        danger: win.tmOn
                        onClicked: win.tmOn ? win.tmStop() : win.tmStart()
                    }
                }
            }

            Column {
                visible: win.tab === "sw"
                anchors.fill: parent
                spacing: 18
                Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; topPadding: 30; text: win.fmtMs(win.swMs); color: AppTheme.text; font.pixelSize: 72; font.weight: Font.Light }
                Center {
                    Row {
                        spacing: 10
                        Pill { label: win.swOn ? "Stop" : "Start"; filled: true; onClicked: win.swToggle() }
                        Pill { label: win.swOn ? "Lap" : "Reset"; onClicked: { if (win.swOn) win.laps = [win.fmtMs(win.swMs)].concat(win.laps); else win.swReset(); } }
                    }
                }
                Repeater {
                    model: win.laps
                    Text { required property string modelData; required property int index; width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Lap " + (win.laps.length - index) + "   " + modelData; color: AppTheme.dim; font.pixelSize: 18 }
                }
            }
        }
    }
}

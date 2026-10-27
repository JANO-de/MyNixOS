import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.suite

ShellRoot {
    SuiteWindow {
        id: win

        title: "Clock"
        implicitWidth: 560
        implicitHeight: 780

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
        function city(z) { return z.substring(z.lastIndexOf("/") + 1).replace(/_/g, " "); }
        function region(z) { return z.indexOf("/") > 0 ? z.substring(0, z.indexOf("/")).replace(/_/g, " ") : ""; }
        function zoneDay(i) { return (win.zoneTimes[i] || "").split(" ")[0]; }
        function zoneTime(i) { return (win.zoneTimes[i] || "").split(" ")[1] || ""; }
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
        function fmtSecs(s) { s = Math.max(0, Math.round(s)); return (s >= 3600 ? pad(Math.floor(s / 3600)) + ":" : "") + pad(Math.floor(s / 60) % 60) + ":" + pad(s % 60); }

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

        Item {
            id: tabs
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: 44
            Seg {
                anchors.horizontalCenter: parent.horizontalCenter
                model: [{ label: "Clock", value: "clock" }, { label: "Alarms", value: "alarm" }, { label: "Timer", value: "timer" }, { label: "Stopwatch", value: "sw" }]
                current: win.tab
                onPicked: value => win.tab = value
            }
        }

        Flickable {
            anchors.top: tabs.bottom
            anchors.topMargin: 12
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            contentWidth: width
            contentHeight: pages.height + 24
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: pages
                x: 16
                width: parent.width - 32
                spacing: 10

                // ---- Clock -------------------------------------------------------------------
                Column {
                    visible: win.tab === "clock"
                    width: parent.width
                    spacing: 10
                    Item {
                        width: parent.width
                        height: 236
                        AnalogClock { anchors.centerIn: parent; width: 220; height: 220; time: clk.date }
                    }
                    Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Qt.formatTime(clk.date, "HH:mm:ss"); color: AppTheme.text; font.pixelSize: 52; font.weight: Font.Light }
                    Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(clk.date, "dddd, d MMMM yyyy"); color: AppTheme.dim; font.pixelSize: 17; bottomPadding: 6 }
                    Sect { text: "World clock" }
                    Repeater {
                        model: zoneStore.value
                        ListRow {
                            required property string modelData
                            required property int index
                            tappable: false
                            title: win.city(modelData)
                            subtitle: (win.region(modelData) !== "" ? win.region(modelData) + "  ·  " : "") + win.zoneDay(index)
                            Item {
                                width: zt.implicitWidth
                                height: 44
                                Text { id: zt; anchors.verticalCenter: parent.verticalCenter; text: win.zoneTime(index); color: AppTheme.text; font.pixelSize: 28; font.weight: Font.Light }
                            }
                            Pill {
                                icon: "close"
                                flat: true
                                onClicked: {
                                    zoneStore.value = zoneStore.value.filter((z, j) => j !== index);
                                    zoneStore.save();
                                    win.refreshZones();
                                }
                            }
                        }
                    }
                    Field {
                        id: zf
                        width: parent.width
                        icon: "globe"
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

                // ---- Alarms ------------------------------------------------------------------
                Column {
                    visible: win.tab === "alarm"
                    width: parent.width
                    spacing: 12
                    Rectangle {
                        width: parent.width
                        height: 210
                        radius: 28
                        color: AppTheme.card
                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Column {
                                width: 120
                                Item { width: parent.width; height: 52; Pill { anchors.centerIn: parent; icon: "up"; flat: true; onClicked: win.ah = (win.ah + 1) % 24 } }
                                Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: win.pad(win.ah); color: AppTheme.text; font.pixelSize: 64; font.weight: Font.Light }
                                Item { width: parent.width; height: 52; Pill { anchors.centerIn: parent; icon: "down"; flat: true; onClicked: win.ah = (win.ah + 23) % 24 } }
                            }
                            Item {
                                width: 20
                                height: 180
                                Text { anchors.centerIn: parent; text: ":"; color: AppTheme.dim; font.pixelSize: 56; font.weight: Font.Light }
                            }
                            Column {
                                width: 120
                                Item { width: parent.width; height: 52; Pill { anchors.centerIn: parent; icon: "up"; flat: true; onClicked: win.am = (win.am + 5) % 60 } }
                                Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: win.pad(win.am); color: AppTheme.text; font.pixelSize: 64; font.weight: Font.Light }
                                Item { width: parent.width; height: 52; Pill { anchors.centerIn: parent; icon: "down"; flat: true; onClicked: win.am = (win.am + 55) % 60 } }
                            }
                        }
                    }
                    Center {
                        Pill { label: "Add alarm"; icon: "plus"; filled: true; onClicked: win.addAlarm() }
                    }
                    Text {
                        visible: alarmStore.value.length === 0
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 8
                        text: "No alarms"
                        color: AppTheme.dim
                        font.pixelSize: 17
                    }
                    Repeater {
                        model: alarmStore.value
                        ListRow {
                            required property var modelData
                            required property int index
                            tappable: false
                            title: modelData.time
                            titleSize: 32
                            dimTitle: !modelData.on
                            subtitle: "Every day"
                            Item {
                                width: 58
                                height: 44
                                Tog { anchors.verticalCenter: parent.verticalCenter; checked: modelData.on; onToggled: win.toggleAlarm(index) }
                            }
                            Pill { icon: "trash"; flat: true; danger: true; onClicked: win.delAlarm(index) }
                        }
                    }
                }

                // ---- Timer -------------------------------------------------------------------
                Column {
                    visible: win.tab === "timer"
                    width: parent.width
                    spacing: 18
                    Item {
                        width: parent.width
                        height: 300
                        Ring {
                            anchors.centerIn: parent
                            width: 280
                            height: 280
                            value: win.tmOn ? Math.max(0, (win.tmEnd - win.now) / (win.tmSecs * 1000)) : 1
                            Text {
                                anchors.centerIn: parent
                                text: win.fmtSecs(win.tmOn ? (win.tmEnd - win.now) / 1000 : win.tmSecs)
                                color: AppTheme.text
                                font.pixelSize: 56
                                font.weight: Font.Light
                            }
                        }
                    }
                    Center {
                        visible: !win.tmOn
                        Row {
                            spacing: 8
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
                        visible: !win.tmOn
                        Row {
                            spacing: 8
                            Pill { label: "−1 min"; onClicked: win.tmSecs = Math.max(60, win.tmSecs - 60) }
                            Pill { label: "+1 min"; onClicked: win.tmSecs += 60 }
                        }
                    }
                    Center {
                        Pill {
                            label: win.tmOn ? "Cancel" : "Start"
                            icon: win.tmOn ? "stop" : "play"
                            filled: !win.tmOn
                            danger: win.tmOn
                            onClicked: win.tmOn ? win.tmStop() : win.tmStart()
                        }
                    }
                }

                // ---- Stopwatch ---------------------------------------------------------------
                Column {
                    visible: win.tab === "sw"
                    width: parent.width
                    spacing: 18
                    Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; topPadding: 40; bottomPadding: 10; text: win.fmtMs(win.swMs); color: AppTheme.text; font.pixelSize: 76; font.weight: Font.Light }
                    Center {
                        Row {
                            spacing: 10
                            Pill { label: win.swOn ? "Stop" : "Start"; icon: win.swOn ? "pause" : "play"; filled: true; onClicked: win.swToggle() }
                            Pill { label: win.swOn ? "Lap" : "Reset"; icon: win.swOn ? "flag" : "refresh"; onClicked: { if (win.swOn) win.laps = [win.fmtMs(win.swMs)].concat(win.laps); else win.swReset(); } }
                        }
                    }
                    Column {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: win.laps
                            ListRow {
                                required property string modelData
                                required property int index
                                tappable: false
                                title: "Lap " + (win.laps.length - index)
                                Text { height: 44; verticalAlignment: Text.AlignVCenter; text: modelData; color: AppTheme.text; font.pixelSize: 22; font.weight: Font.Light }
                            }
                        }
                    }
                }
            }
        }
    }
}

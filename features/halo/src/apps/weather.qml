import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.suite

ShellRoot {
    SuiteWindow {
        id: win

        title: "Weather"
        implicitWidth: 520
        implicitHeight: 660

        property var wx: ({ ok: false })
        function fetch() {
            if (!proc.running)
                proc.running = true;
        }
        function condIcon(c) {
            const s = String(c).toLowerCase();
            if (/thunder|storm/.test(s))
                return "bolt";
            if (/snow|sleet|ice|blizzard/.test(s))
                return "snow";
            if (/rain|drizzle|shower/.test(s))
                return "rain";
            if (/fog|mist|haze/.test(s))
                return "fog";
            if (/sun|clear/.test(s))
                return "sun";
            return "cloud";
        }
        Component.onCompleted: fetch()

        Process {
            id: proc
            command: ["curl", "-s", "-m", "10", "wttr.in/?format=%t|%C|%l|%h|%w"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const f = text.trim().split("|");
                    if (f.length >= 5 && f[0] !== "" && text.indexOf("Unknown") < 0 && text.indexOf("<") < 0)
                        win.wx = { ok: true, temp: f[0].replace("+", ""), cond: f[1], loc: f[2], hum: f[3], wind: f[4] };
                    else
                        win.wx = { ok: false };
                }
            }
        }
        Timer { interval: 900000; repeat: true; running: true; onTriggered: win.fetch() }

        actions: [
            Pill { icon: "refresh"; enabled: !proc.running; onClicked: win.fetch() }
        ]

        Column {
            visible: win.wx.ok
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                width: parent.width
                height: parent.height - 76 - 12
                radius: 32
                color: AppTheme.card

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 32
                    spacing: 6
                    Item {
                        width: parent.width
                        height: 30
                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Ico { name: "location"; size: 22; color: AppTheme.accent }
                            Text { text: win.wx.ok ? win.wx.loc : ""; color: AppTheme.text; font.pixelSize: 22; font.weight: Font.Medium }
                        }
                    }
                    Item {
                        width: parent.width
                        height: 120
                        Ico { anchors.centerIn: parent; name: win.wx.ok ? win.condIcon(win.wx.cond) : "cloud"; size: 104; color: AppTheme.accent }
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: win.wx.ok ? win.wx.temp : ""
                        color: AppTheme.text
                        font.pixelSize: 88
                        font.weight: Font.Light
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: win.wx.ok ? win.wx.cond : ""
                        color: AppTheme.dim
                        font.pixelSize: 22
                    }
                }
            }

            Row {
                width: parent.width
                height: 76
                spacing: 12
                Repeater {
                    model: win.wx.ok ? [{ ico: "drop", lab: "Humidity", val: win.wx.hum }, { ico: "wind", lab: "Wind", val: win.wx.wind }] : []
                    Rectangle {
                        required property var modelData
                        width: (parent.width - 12) / 2
                        height: 76
                        radius: 22
                        color: AppTheme.card
                        Badge { x: 16; anchors.verticalCenter: parent.verticalCenter; icon: modelData.ico }
                        Column {
                            x: 70
                            width: parent.width - 80
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text { width: parent.width; text: modelData.lab; color: AppTheme.dim; font.pixelSize: 13 }
                            Text { width: parent.width; text: modelData.val; color: AppTheme.text; font.pixelSize: 20; elide: Text.ElideRight }
                        }
                    }
                }
            }
        }

        Empty {
            visible: !win.wx.ok
            anchors.centerIn: parent
            icon: "cloud"
            text: proc.running ? "Loading weather…" : "No weather data.\nCheck the connection and tap refresh."
        }
    }
}

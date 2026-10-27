import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

ShellRoot {
    AppWindow {
        id: win

        title: "Weather"
        implicitWidth: 520
        implicitHeight: 620

        property var wx: ({ ok: false })
        function fetch() {
            if (!proc.running)
                proc.running = true;
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

        Column {
            anchors.centerIn: parent
            spacing: 16
            Text { width: 420; horizontalAlignment: Text.AlignHCenter; text: win.wx.ok ? win.wx.loc : "Weather"; color: AppTheme.text; font.pixelSize: 26 }
            Text { width: 420; horizontalAlignment: Text.AlignHCenter; text: win.wx.ok ? win.wx.temp : "--"; color: AppTheme.text; font.pixelSize: 72; font.weight: Font.Light }
            Text { width: 420; horizontalAlignment: Text.AlignHCenter; text: win.wx.ok ? win.wx.cond : "Loading..."; color: AppTheme.dim; font.pixelSize: 22 }
            Text { visible: win.wx.ok; width: 420; horizontalAlignment: Text.AlignHCenter; text: win.wx.ok ? ("Humidity " + win.wx.hum + "  ·  Wind " + win.wx.wind) : ""; color: AppTheme.dim; font.pixelSize: 16 }
            Pill { anchors.horizontalCenter: parent.horizontalCenter; label: "Refresh"; onClicked: win.fetch() }
        }
    }
}

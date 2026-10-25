pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared data for home-screen widgets: pollers run only while a widget uses them (use("sys"|"wx", +1/-1)),
// and timer/stopwatch state lives here so it survives a widget being re-created (stack swipe, page change).
Singleton {
    id: root

    property int sysUsers: 0
    property int wxUsers: 0
    function use(kind, d) {
        if (kind === "sys")
            sysUsers = Math.max(0, sysUsers + d);
        else if (kind === "wx")
            wxUsers = Math.max(0, wxUsers + d);
    }

    // ---- system stats ----
    property real cpu: 0
    property real mem: 0
    property real memUsed: 0
    property real memTotal: 0
    property real disk: 0
    property real diskUsed: 0
    property real diskSize: 0
    property string uptime: ""
    property var prevCpu: null

    function gb(bytes) {
        const g = bytes / 1073741824;
        return (g >= 100 ? g.toFixed(0) : g.toFixed(1)) + " GB";
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.sysUsers > 0
        triggeredOnStart: true
        onTriggered: if (!sysProc.running) sysProc.running = true
    }
    Process {
        id: sysProc
        command: ["sh", "-c", "head -n1 /proc/stat; awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{print t, a}' /proc/meminfo; df -B1 --output=size,used / | tail -n1; uptime -p"]
        stdout: StdioCollector {
            onStreamFinished: root.parseSys(text)
        }
    }
    function parseSys(t) {
        const l = t.split("\n");
        const c = (l[0] || "").trim().split(/\s+/).slice(1).map(x => parseFloat(x));
        if (c.length >= 5) {
            const idle = c[3] + c[4];
            const total = c.reduce((a, b) => a + b, 0);
            if (prevCpu) {
                const dt = total - prevCpu.total;
                const di = idle - prevCpu.idle;
                if (dt > 0)
                    cpu = Math.max(0, Math.min(1, 1 - di / dt));
            }
            prevCpu = { total: total, idle: idle };
        }
        const m = (l[1] || "").trim().split(/\s+/).map(x => parseFloat(x) * 1024);
        if (m.length >= 2 && m[0] > 0) {
            memTotal = m[0];
            memUsed = m[0] - m[1];
            mem = memUsed / memTotal;
        }
        const d = (l[2] || "").trim().split(/\s+/).map(x => parseFloat(x));
        if (d.length >= 2 && d[0] > 0) {
            diskSize = d[0];
            diskUsed = d[1];
            disk = d[1] / d[0];
        }
        uptime = (l[3] || "").replace(/^up /, "");
    }

    // ---- weather (wttr.in, location by IP) ----
    property var wx: ({ ok: false })
    property double wxAt: 0
    function fetchWx() {
        if (!wxProc.running)
            wxProc.running = true;
    }
    onWxUsersChanged: if (wxUsers > 0 && Date.now() - wxAt > 900000) fetchWx()
    Timer {
        interval: 1800000
        repeat: true
        running: root.wxUsers > 0
        onTriggered: root.fetchWx()
    }
    Process {
        id: wxProc
        command: ["curl", "-s", "-m", "10", "wttr.in/?format=%t|%C|%l|%h|%w"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("|");
                if (f.length >= 5 && f[0] !== "" && text.indexOf("Unknown") < 0 && text.indexOf("<") < 0) {
                    root.wx = { ok: true, temp: f[0].replace("+", ""), cond: f[1], loc: f[2], hum: f[3], wind: f[4] };
                    root.wxAt = Date.now();
                } else if (!root.wx.ok) {
                    root.wx = { ok: false };
                }
            }
        }
    }

    // ---- stopwatch ----
    property bool swRun: false
    property double swStart: 0
    property real swAcc: 0 // ms
    function swElapsed() { return swAcc + (swRun ? Date.now() - swStart : 0); }
    function swToggle() {
        if (swRun) {
            swAcc += Date.now() - swStart;
            swRun = false;
        } else {
            swStart = Date.now();
            swRun = true;
        }
    }
    function swReset() { swRun = false; swAcc = 0; }

    // ---- countdown timer ----
    property int tmDur: 300 // seconds
    property bool tmRun: false
    property double tmEnd: 0
    property real tmLeft: 300
    function tmRemaining() { return tmRun ? Math.max(0, (tmEnd - Date.now()) / 1000) : tmLeft; }
    function tmStart() {
        if (tmRun || tmLeft <= 0)
            return;
        tmEnd = Date.now() + tmLeft * 1000;
        tmRun = true;
    }
    function tmPause() {
        if (!tmRun)
            return;
        tmLeft = Math.max(0, (tmEnd - Date.now()) / 1000);
        tmRun = false;
    }
    function tmSet(sec) { tmRun = false; tmDur = sec; tmLeft = sec; }
    Timer {
        interval: 250
        repeat: true
        running: root.tmRun
        onTriggered: {
            if (Date.now() >= root.tmEnd) {
                root.tmRun = false;
                root.tmLeft = 0;
                Quickshell.execDetached(["notify-send", "-t", "8000", "Timer", "Time is up"]);
            }
        }
    }
}

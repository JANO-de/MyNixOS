// =============================================================================
//  Clocks — stopwatch and countdown timer, shared by the island panel and idle pill.
//  Stopwatch: swToggle() swReset() swLap()   swMs   laps
//  Timer:     tSet(ms) tToggle() tReset()    tLeft  tDuration  tRunning
//  When the timer ends it sends a desktop notification (shows as an island banner).
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    // ---- stopwatch
    property bool swRunning: false
    property real swBase: 0          // ms accumulated before the current run
    property real swStart: 0
    property real swMs: 0
    property var laps: []            // newest first, total ms at each lap
    function swToggle() {
        if (swRunning) { swBase += Date.now() - swStart; swRunning = false }
        else { swStart = Date.now(); swRunning = true }
        swMs = swBase + (swRunning ? Date.now() - swStart : 0);
    }
    function swReset() { swRunning = false; swBase = 0; swMs = 0; laps = [] }
    function swLap() { if (swRunning || swMs > 0) laps = [swMs].concat(laps).slice(0, 20) }

    // ---- timer
    property real tDuration: 300000
    property real tLeft: 300000
    property bool tRunning: false
    property real tEnd: 0
    function tSet(ms) { tRunning = false; tDuration = Math.max(1000, ms); tLeft = tDuration }
    function tToggle() {
        if (tRunning) { tLeft = Math.max(0, tEnd - Date.now()); tRunning = false }
        else { if (tLeft <= 0) tLeft = tDuration; tEnd = Date.now() + tLeft; tRunning = true }
    }
    function tReset() { tRunning = false; tLeft = tDuration }

    readonly property bool active: swRunning || tRunning

    Timer {
        interval: 50; repeat: true; running: root.active
        onTriggered: {
            if (root.swRunning) root.swMs = root.swBase + Date.now() - root.swStart;
            if (root.tRunning) {
                root.tLeft = Math.max(0, root.tEnd - Date.now());
                if (root.tLeft <= 0) {
                    root.tRunning = false;
                    Quickshell.execDetached(["notify-send", "-a", "Timer", "-u", "critical", "Timer finished", root.fmt(root.tDuration, false)]);
                }
            }
        }
    }

    // 3725000 -> "1:02:05" ; with cs=true -> "02:05.00"
    function fmt(ms, cs) {
        const t = Math.max(0, Math.floor(ms / 10) / 100);
        const h = Math.floor(t / 3600), m = Math.floor(t % 3600 / 60), s = Math.floor(t % 60);
        const p = n => (n < 10 ? "0" : "") + n;
        let out = (h > 0 ? h + ":" + p(m) : p(m)) + ":" + p(s);
        if (cs) out += "." + p(Math.floor((t * 100) % 100));
        return out;
    }
}

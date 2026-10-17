// Pomodoro timer: work / short break / long break cycles. Shown in the Clock panel (3rd tab)
// and as a live activity on the island while running. Durations: Settings > System.
pragma Singleton
import QtQuick
import Quickshell
import qs.config
import qs.services

Singleton {
    id: root
    property bool running: false
    property string phase: "work"          // work | break | long
    property int done: 0                   // finished focus sessions
    property real endAt: 0
    property real leftMs: Config.system.pomoWork * 60000
    readonly property real totalMs: (phase === "work" ? Config.system.pomoWork : phase === "break" ? Config.system.pomoBreak : Config.system.pomoLong) * 60000
    readonly property string label: phase === "work" ? "Focus" : phase === "break" ? "Short break" : "Long break"

    function fmt(ms) { const s = Math.max(0, Math.ceil(ms / 1000)); return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0") }
    function setPhase(p) { phase = p; leftMs = totalMs }
    function toggle() {
        if (running) { leftMs = Math.max(0, endAt - Date.now()); running = false; Activities.clear("pomo") }
        else { endAt = Date.now() + leftMs; running = true; tick() }
    }
    function reset() { running = false; done = 0; setPhase("work"); Activities.clear("pomo") }
    function skip() { setPhase(phase === "work" ? "break" : "work"); if (running) { endAt = Date.now() + leftMs; tick() } }
    function tick() {
        const left = endAt - Date.now();
        if (left <= 0) { finish(); return }
        leftMs = left;
        Activities.push("pomo", label + " " + fmt(left), phase === "work" ? "timer" : "local_cafe", 1 - left / totalMs, phase === "work" ? "#ef5350" : "#66bb6a", 0)
    }
    function finish() {
        const was = phase;
        if (was === "work") { done++; setPhase(done % Config.system.pomoEvery === 0 ? "long" : "break") } else setPhase("work");
        Quickshell.execDetached(["notify-send", "-a", "Pomodoro", was === "work" ? "Time for a break" : "Back to focus", label + " · " + Math.round(totalMs / 60000) + " min"]);
        if (Config.system.pomoAuto) { endAt = Date.now() + leftMs; tick() } else { running = false; Activities.clear("pomo") }
    }
    Timer { interval: 1000; repeat: true; running: root.running; onTriggered: root.tick() }
}

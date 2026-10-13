// Agenda singleton. pragma must stay at the top (Quickshell detects it there).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import "ics.js" as Ics

// Agenda: calendar events (see docs/calendar-sync.md).
// Not named "Calendar": that collides with a Qt built-in.
// API: eventsOn(date) hasEvents(date) upcoming(n) sync() status syncing
// Sources: Config.calendar.sources [{name, kind: url|folder, value, color}]
Singleton {
    id: root
    readonly property var cfg: Config.calendar
    property var events: []            // flat list, all sources
    property var byDay: ({})
    property string status: ""
    property bool syncing: false
    property var perSource: ({})       // name -> expanded events
    property var errors: ({})
    property var queue: []
    property var current: null
    property string pendingText: ""
    property int pendingParts: 0
    property int pendingCode: 0

    function eventsOn(d) { return byDay[Ics.dayKey(d)] || [] }
    function hasEvents(d) { return (byDay[Ics.dayKey(d)] || []).length > 0 }
    function upcoming(n) {
        const now = Date.now();
        return events.filter(e => e.end.getTime() >= now).sort((a, b) => a.start - b.start).slice(0, n);
    }

    function expandHome(p) { return p.replace(/^~/, Quickshell.env("HOME")) }

    function rebuild() {
        let all = [];
        for (const k in perSource) all = all.concat(perSource[k]);
        events = all;
        byDay = Ics.indexByDay(all);
    }

    function sync() {
        if (syncing) return;
        const srcs = cfg.sources ? Array.from(cfg.sources) : [];
        if (!cfg.enabled || srcs.length === 0) { status = srcs.length === 0 ? "No calendar sources yet" : "Calendar disabled"; return }
        syncing = true; errors = ({}); queue = srcs; status = "Syncing...";
        if (cfg.vdirsyncer) vd.running = true; else next();
    }

    function next() {
        if (queue.length === 0) {
            syncing = false; rebuild();
            const bad = Object.keys(errors);
            status = bad.length ? "Problem with: " + bad.join(", ") : "Synced " + Qt.formatTime(new Date(), "hh:mm");
            return;
        }
        current = queue[0]; queue = queue.slice(1);
        pendingText = ""; pendingParts = 2; pendingCode = 0;
        if (current.kind === "folder")
            runner.command = ["sh", "-c", "find \"$1\" -name '*.ics' -exec cat {} +", "sh", expandHome(current.value)];
        else
            runner.command = ["curl", "-fsSL", "--max-time", "30", current.value];
        runner.running = true;
    }

    // stdout and exit arrive in either order: finish when both have
    function part() {
        if (--pendingParts > 0) return;
        const src = current;
        if (pendingCode !== 0) {
            errors[src.name] = "exit " + pendingCode;
            console.warn("Calendar:", src.name, "failed with code", pendingCode);
        } else {
            try {
                const now = new Date();
                const ws = new Date(now.getFullYear(), now.getMonth() - 2, 1), we = new Date(now.getFullYear(), now.getMonth() + 5, 1);
                const ex = Ics.expand(Ics.parse(pendingText), ws, we, { name: src.name, color: src.color || "#8bd5a0" });
                perSource[src.name] = ex;
            } catch (e) { errors[src.name] = "parse"; console.warn("Calendar: parse error", src.name, e) }
        }
        next();
    }

    Process {
        id: runner
        stdout: StdioCollector { onStreamFinished: { root.pendingText = text; root.part() } }
        onExited: code => { root.pendingCode = code; root.part() }
    }
    Process {   // optional CalDAV sync before reading the folders
        id: vd
        command: ["vdirsyncer", "sync"]
        onExited: code => { if (code !== 0) console.warn("Calendar: vdirsyncer sync exited with", code); root.next() }
    }

    Timer {
        interval: Math.max(5, root.cfg.syncMinutes) * 60000
        repeat: true; running: root.cfg.enabled && !Server.active; triggeredOnStart: true
        onTriggered: root.sync()
    }
    // sources edited in Settings -> resync soon
    readonly property string sig: JSON.stringify(cfg.sources) + cfg.vdirsyncer + cfg.enabled
    onSigChanged: resyncT.restart()
    Timer { id: resyncT; interval: 800; onTriggered: { root.syncing = false; root.sync() } }
}

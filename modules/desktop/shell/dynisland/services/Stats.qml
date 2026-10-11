// =============================================================================
//  Stats — CPU / RAM / disk usage, polled every 2 s ONLY while `watching`.
//  Stats.cpu, Stats.ram, Stats.disk  are 0..1.   Stats.ramText e.g. "6.2 / 16 GB".
//  The system desktop widget sets `watching` from Config.widgets.system.
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool watching: false
    property real cpu: 0
    property real ram: 0
    property real disk: 0
    property string ramText: ""
    property var prev: null          // previous {total, idle} sample, for the CPU delta

    Timer { interval: 2000; repeat: true; triggeredOnStart: true; running: root.watching; onTriggered: p.running = true }

    Process {
        id: p
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable)' /proc/meminfo; df -P / | tail -1"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    function parse(t) {
        let memTotal = 0, memAvail = 0;
        for (const line of t.split("\n")) {
            const f = line.trim().split(/\s+/);
            if (f[0] === "cpu") {
                const n = f.slice(1, 9).map(Number);
                const total = n.reduce((a, b) => a + b, 0), idle = n[3] + n[4];
                if (root.prev && total > root.prev.total)
                    root.cpu = Math.max(0, Math.min(1, 1 - (idle - root.prev.idle) / (total - root.prev.total)));
                root.prev = { total: total, idle: idle };
            } else if (f[0] === "MemTotal:") memTotal = Number(f[1]);
            else if (f[0] === "MemAvailable:") memAvail = Number(f[1]);
            else if (f[0].indexOf("/") === 0 && f.length >= 5) root.disk = (parseInt(f[4]) || 0) / 100;   // "45%"
        }
        if (memTotal > 0) {
            root.ram = 1 - memAvail / memTotal;
            const gb = k => (k / 1048576).toFixed(1);
            root.ramText = gb(memTotal - memAvail) + " / " + gb(memTotal) + " GB";
        }
    }
}

// Drive notifications: connected / mounted / unmounted / removed (hotplug drives only).
// Polls `lsblk` every 3 s (cheap), diffs against the last snapshot, notifies via notify-send.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root
    property bool ready: true
    property var snap: null          // null until the first scan (no notifications for drives already plugged in)

    function note(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Drives", "-i", "drive-removable-media-usb", title, body]);
    }
    function parse(t) {
        const cur = {};
        for (const line of t.split("\n")) {
            if (!line) continue;
            const f = line.split(" ");   // NAME LABEL SIZE HOTPLUG TYPE MOUNTPOINT (raw mode: empty fields stay empty)
            if (f.length < 5 || f[3] !== "1" || f[4] !== "part") continue;
            const unesc = s => s.replace(/\\x20/g, " ");
            cur[f[0]] = { label: unesc(f[1] || "") || f[0].split("/").pop(), size: f[2], mnt: unesc(f.slice(5).join(" ")) };
        }
        if (root.snap && Config.system.usbNotify) {
            for (const k in cur) {
                const n = cur[k], o = root.snap[k];
                if (!o) root.note("Drive connected", n.label + " (" + n.size + ")");
                else if (!o.mnt && n.mnt) root.note("Drive mounted", n.label + " at " + n.mnt);
                else if (o.mnt && !n.mnt) root.note("Drive unmounted", n.label + " can be removed");
            }
            for (const k in root.snap) if (!cur[k]) root.note("Drive removed", root.snap[k].label);
        }
        root.snap = cur;
    }
    Timer { interval: 3000; repeat: true; running: Config.system.usbNotify; triggeredOnStart: true; onTriggered: p.running = true }
    Process {
        id: p
        command: ["lsblk", "-rpno", "NAME,LABEL,SIZE,HOTPLUG,TYPE,MOUNTPOINT"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
}

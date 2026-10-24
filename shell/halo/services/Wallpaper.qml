pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper choice: built-in procedural presets + bundled images (/etc/halo/wallpapers) + ~/Pictures/Wallpapers.
// A spec is "preset:<id>" or "file:<absolute path>". Saved to ~/.config/halo/wallpaper.json.
Singleton {
    id: root

    property string current: "preset:contours"
    property var files: []

    readonly property var presets: [
        { id: "contours", kind: "topo", bg: "#232426", line: "#0f8a9c" },
        { id: "night", kind: "gradient", c1: "#0b1020", c2: "#1f3358" },
        { id: "aurora", kind: "gradient", c1: "#04201f", c2: "#14756e" },
        { id: "dusk", kind: "gradient", c1: "#1a1030", c2: "#6a2f7e" },
        { id: "graphite", kind: "gradient", c1: "#121214", c2: "#34343a" }
    ]
    readonly property string dir: Quickshell.env("HOME") + "/.config/halo"
    readonly property string picsDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    function preset(id) {
        for (const p of presets)
            if (p.id === id)
                return p;
        return null;
    }

    // All selectable specs, presets first.
    readonly property var specs: {
        const out = presets.map(p => "preset:" + p.id);
        for (const f of files)
            out.push("file:" + f);
        return out;
    }

    // Current first, then the others (for the long-press menu thumbnails).
    function quick(n) {
        const out = [current];
        for (const s of specs) {
            if (out.length >= n)
                break;
            if (s !== current)
                out.push(s);
        }
        return out;
    }

    function set(spec) {
        current = spec;
        file.setText(JSON.stringify({ current: spec }));
    }

    function rescan() {
        scan.running = true;
    }

    Process {
        id: scan
        command: ["sh", "-c", "mkdir -p \"$HOME/Pictures/Wallpapers\"; find -L /etc/halo/wallpapers \"$HOME/Pictures/Wallpapers\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | sort"]
        stdout: StdioCollector {
            onStreamFinished: root.files = text.trim() === "" ? [] : text.trim().split("\n")
        }
    }

    FileView {
        id: file
        path: root.dir + "/wallpaper.json"
        atomicWrites: true
        onLoaded: {
            try {
                const p = JSON.parse(text());
                if (typeof p.current === "string")
                    root.current = p.current;
            } catch (e) {}
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.dir]);
        rescan();
    }
}

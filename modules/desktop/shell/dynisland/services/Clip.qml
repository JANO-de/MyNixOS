// =============================================================================
//  Clip — clipboard history via cliphist (+ wl-paste watchers while enabled).
//  Panel: UiState.openPanel("clipboard"). Settings: Config.system.clip*.
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root
    property var items: []          // [{id, text, image}] newest first
    property var _buf: []

    function refresh() { _buf = []; listProc.running = false; listProc.running = true }
    function copy(id) { Quickshell.execDetached(["sh", "-c", "cliphist decode " + id + " | wl-copy"]) }
    function remove(id) {
        Quickshell.execDetached(["sh", "-c", "printf '%s\\t\\n' " + id + " | cliphist delete"]);
        items = items.filter(i => i.id !== id)
    }
    function wipe() { Quickshell.execDetached(["cliphist", "wipe"]); items = [] }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: SplitParser {
            onRead: line => {
                const t = line.indexOf("\t");
                if (t < 1) return;
                const txt = line.slice(t + 1);
                root._buf.push({ id: line.slice(0, t), text: txt, image: txt.indexOf("[[ binary data") === 0 });
            }
        }
        onRunningChanged: if (!running) root.items = root._buf.slice(0, Config.system.clipMax)
    }
    Process {
        running: Config.system.clipWatch
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "-max-items", String(Config.system.clipMax), "store"]
    }
    Process {
        running: Config.system.clipWatch && Config.system.clipImages
        command: ["wl-paste", "--type", "image", "--watch", "cliphist", "-max-items", String(Config.system.clipMax), "store"]
    }
}

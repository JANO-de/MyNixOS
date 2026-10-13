// =============================================================================
//  Niri — window list for the dock (running dots / focusing).
//  Uses `niri msg event-stream` (push), so no polling.
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var windows: []   // [{id, app_id, title, ...}]

    function focus(id) { Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(id)]) }
    function close(id) { Quickshell.execDetached(["niri", "msg", "action", "close-window", "--id", String(id)]) }
    function windowsFor(appId) {
        const a = (appId || "").toLowerCase();
        return windows.filter(w => (w.app_id || "").toLowerCase() === a);
    }

    Process {
        running: true
        command: ["niri", "msg", "-j", "event-stream"]
        stdout: SplitParser { onRead: line => { if (line.indexOf("Window") >= 0) debounce.restart() } }
    }
    Timer { id: debounce; interval: 120; onTriggered: list.running = true }
    Process {
        id: list; command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector { onStreamFinished: { try { root.windows = JSON.parse(text) } catch (e) {} } }
    }
    Component.onCompleted: list.running = true
}

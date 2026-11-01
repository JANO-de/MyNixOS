// =============================================================================
//  Wm — compositor-agnostic window / workspace state (replaces Niri.qml).
//  Works on mango (mmsg) and niri (niri msg). Used by the dock (running dots,
//  focus, close), the island/dock "dodge" mode, per-workspace wallpapers and
//  Server mode (monitor power).
//
//  Same shape the old Niri singleton had, so callers only changed Niri -> Wm:
//    windows     [{id, app_id, title, workspace_id, output, is_floating, is_focused}]
//    workspaces  [{id, idx, name, output, is_active}]
//    busy(output)  is a tiled window on this output's active workspace/tag?
//    focus(id) / close(id) / windowsFor(appId) / monitorsOff() / monitorsOn()
//
//  mango note: the JSON field names of `mmsg get all-clients|all-monitors` are not
//  documented, so every field is read through pick() with a few likely spellings.
//  If the dock shows no running dots, run `mmsg get all-clients | head -c 1500`,
//  and `journalctl --user -u dynisland | grep Wm:` prints a sample as seen here.
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string kind: Quickshell.env("NIRI_SOCKET") ? "niri"
                                 : Quickshell.env("MANGO_INSTANCE_SIGNATURE") ? "mango" : "none"

    property var windows: []
    property var workspaces: []
    property var monitorNames: []
    property bool _logged: false

    function pick(o, keys, dflt) {
        for (const k of keys) if (o[k] !== undefined && o[k] !== null) return o[k];
        return dflt;
    }
    function asList(j) {
        if (Array.isArray(j)) return j;
        if (j && typeof j === "object") {
            for (const k of ["clients", "monitors", "items", "data"]) if (Array.isArray(j[k])) return j[k];
            return Object.values(j);
        }
        return [];
    }
    function maskOf(v) {            // tag mask from a number, "1|3" style string, or array of tag numbers
        if (typeof v === "number") return v;
        if (Array.isArray(v)) return v.reduce((m, t) => m | (1 << (Number(t) - 1)), 0);
        const n = Number(v);
        return isNaN(n) ? 0 : n;
    }
    function lowestTag(mask) {      // 1-based index of the lowest set bit (0 if none)
        for (let i = 0; i < 31; i++) if (mask & (1 << i)) return i + 1;
        return 0;
    }

    // ---- shared API --------------------------------------------------------
    function busy(output) {
        if (kind === "niri") {
            const ws = workspaces.find(w => w.is_active && (!output || w.output === output));
            if (!ws) return false;
            return windows.some(w => w.workspace_id === ws.id && !w.is_floating);
        }
        // mango: any tiled, visible window on this output
        return windows.some(w => !w.is_floating && !w.minimized && w.visible && (!output || !w.output || w.output === output));
    }
    function focus(id) {
        if (kind === "niri") Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(id)]);
        else if (kind === "mango") Quickshell.execDetached(["mmsg", "dispatch", "focusid", "client," + id]);
    }
    function close(id) {
        if (kind === "niri") Quickshell.execDetached(["niri", "msg", "action", "close-window", "--id", String(id)]);
        else if (kind === "mango") Quickshell.execDetached(["mmsg", "dispatch", "killclient", "client," + id]);
    }
    function windowsFor(appId) {
        const a = (appId || "").toLowerCase();
        return windows.filter(w => (w.app_id || "").toLowerCase() === a);
    }
    function monitorsOff() {
        if (kind === "niri") Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
        else if (kind === "mango") monitorNames.forEach(n => Quickshell.execDetached(["mmsg", "dispatch", "sleep_monitor," + n]));
    }
    function monitorsOn() {
        if (kind === "niri") Quickshell.execDetached(["niri", "msg", "action", "power-on-monitors"]);
        else if (kind === "mango") monitorNames.forEach(n => Quickshell.execDetached(["mmsg", "dispatch", "wakeup_monitor," + n]));
    }

    function refresh() {
        if (kind === "niri") { nList.running = true; nWs.running = true }
        else if (kind === "mango") { mMons.running = true }   // clients are fetched after monitors (need the tag masks)
    }
    Timer { id: debounce; interval: 120; onTriggered: root.refresh() }
    Component.onCompleted: refresh()

    // ---- niri ----------------------------------------------------------------
    Process {
        running: root.kind === "niri"
        command: ["niri", "msg", "-j", "event-stream"]
        stdout: SplitParser { onRead: line => { if (line.indexOf("Window") >= 0 || line.indexOf("Workspace") >= 0) debounce.restart() } }
    }
    Process {
        id: nList; command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector { onStreamFinished: { try { root.windows = JSON.parse(text).map(w => Object.assign({ visible: true }, w)) } catch (e) {} } }
    }
    Process {
        id: nWs; command: ["niri", "msg", "-j", "workspaces"]
        stdout: StdioCollector { onStreamFinished: { try { root.workspaces = JSON.parse(text) } catch (e) {} } }
    }

    // ---- mango -------------------------------------------------------------
    property var _monMasks: ({})     // output name -> active tag mask
    Process {
        id: wClients; running: root.kind === "mango"; command: ["mmsg", "watch", "all-clients"]
        stdout: SplitParser { onRead: line => debounce.restart() }
        onExited: retry.restart()
    }
    Process {
        id: wTags; running: root.kind === "mango"; command: ["mmsg", "watch", "all-tags"]
        stdout: SplitParser { onRead: line => debounce.restart() }
        onExited: retry.restart()
    }
    Timer { id: retry; interval: 3000; onTriggered: { if (root.kind === "mango") { wClients.running = true; wTags.running = true; root.refresh() } } }

    Process {
        id: mMons; command: ["mmsg", "get", "all-monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const mons = root.asList(JSON.parse(text));
                    const names = [], masks = {}, ws = [];
                    for (const m of mons) {
                        const name = String(root.pick(m, ["name", "output", "monitor"], ""));
                        if (!name) continue;
                        names.push(name);
                        const mask = root.maskOf(root.pick(m, ["tagset", "active_tags", "activetags", "seltags", "tags", "tag"], 0));
                        masks[name] = mask;
                        const idx = root.lowestTag(mask);
                        if (idx) ws.push({ id: name + ":" + idx, idx: idx, name: "", output: name, is_active: true });
                    }
                    root.monitorNames = names; root._monMasks = masks; root.workspaces = ws;
                } catch (e) {}
                mClients.running = true;
            }
        }
    }
    Process {
        id: mClients; command: ["mmsg", "get", "all-clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = root.asList(JSON.parse(text));
                    root.windows = list.map(c => {
                        const mon = root.pick(c, ["monitor", "output", "monitor_name", "mon"], "");
                        const out = (mon && typeof mon === "object") ? String(mon.name || "") : String(mon);
                        const cmask = root.maskOf(root.pick(c, ["tags", "tag", "tagmask", "tag_mask"], 0));
                        const mmask = root._monMasks[out];
                        const vis = root.pick(c, ["visible", "is_visible"], undefined);
                        return {
                            id: root.pick(c, ["id", "address", "window_id"], -1),
                            app_id: String(root.pick(c, ["app_id", "appid", "app-id", "class"], "")),
                            title: String(root.pick(c, ["title"], "")),
                            output: out,
                            workspace_id: cmask,
                            is_floating: !!root.pick(c, ["floating", "is_floating", "isfloating"], false),
                            is_focused: !!root.pick(c, ["focused", "is_focused", "focus", "activated"], false),
                            minimized: !!root.pick(c, ["minimized", "is_minimized"], false),
                            visible: vis !== undefined ? !!vis : (cmask && mmask ? (cmask & mmask) !== 0 : true)
                        };
                    });
                    if (!root._logged && list.length) { root._logged = true; console.log("Wm: sample mango client:", JSON.stringify(list[0])) }
                } catch (e) { console.log("Wm: could not parse mmsg get all-clients:", e) }
            }
        }
    }
}

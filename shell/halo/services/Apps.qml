pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Dock model: pinned favourites first, then any other running app.
// Running state comes from wlr-foreign-toplevel (ToplevelManager), so it needs no Hyprland IPC.
Singleton {
    id: root

    // Matched with DesktopEntries.heuristicLookup. Saved to ~/.config/halo/dock.json once edited.
    property var pinned: ["Alacritty", "org.kde.angelfish", "com.adilhanney.saber", "org.pwmt.zathura", "org.pulseaudio.pavucontrol", "btop"]
    readonly property string dir: Quickshell.env("HOME") + "/.config/halo"

    function pinnedIndexOf(entry) {
        if (!entry)
            return -1;
        for (let i = 0; i < pinned.length; i++) {
            const e = DesktopEntries.heuristicLookup(pinned[i]);
            if (e && e.id === entry.id)
                return i;
        }
        return -1;
    }
    function isPinned(entry) { return pinnedIndexOf(entry) >= 0; }
    function pin(entry) {
        if (!entry || isPinned(entry))
            return;
        pinned = pinned.concat([entry.id]);
        savePins();
    }
    // Pin at a visible dock position (vi counts only pinned items that resolved to an app); an already
    // pinned app is moved there instead. Used by home-screen -> dock drops.
    function pinAtVisible(entry, vi) {
        if (!entry || !entry.id)
            return;
        const vis = items.filter(i => i.pinIndex >= 0);
        const at = vi < vis.length ? vis[Math.max(0, vi)].pinIndex : pinned.length;
        const cur = pinnedIndexOf(entry);
        const a = pinned.slice();
        if (cur >= 0) {
            const x = a.splice(cur, 1)[0];
            a.splice(cur < at ? at - 1 : at, 0, x);
        } else {
            a.splice(at, 0, entry.id);
        }
        pinned = a;
        savePins();
    }
    function unpin(idx) {
        pinned = pinned.filter((_, i) => i !== idx);
        savePins();
    }
    function unpinEntry(entry) { unpin(pinnedIndexOf(entry)); }
    function movePin(from, to) {
        if (from === to || from < 0 || to < 0 || from >= pinned.length || to >= pinned.length)
            return;
        const a = pinned.slice();
        const x = a.splice(from, 1)[0];
        a.splice(to, 0, x);
        pinned = a;
        savePins();
    }
    function savePins() { pinFile.setText(JSON.stringify({ pinned: pinned })); }

    FileView {
        id: pinFile
        path: root.dir + "/dock.json"
        atomicWrites: true
        onLoaded: {
            try {
                const p = JSON.parse(text());
                if (Array.isArray(p.pinned))
                    root.pinned = p.pinned;
            } catch (e) {}
        }
    }

    function norm(s) {
        return String(s || "").toLowerCase();
    }

    function matches(entry, appId) {
        const a = norm(appId);
        if (a === "")
            return false;
        return norm(entry.id) === a || norm(entry.startupClass) === a || norm(entry.name) === a;
    }

    function build() {
        // Touch both models so the binding re-runs when either changes.
        const apps = DesktopEntries.applications.values;
        const tops = ToplevelManager.toplevels.values;
        const out = [];
        const used = [];

        for (let pi = 0; pi < pinned.length; pi++) {
            const name = pinned[pi];
            const e = DesktopEntries.heuristicLookup(name);
            if (!e)
                continue;
            const wins = [];
            if (e) {
                for (const t of tops) {
                    if (matches(e, t.appId)) {
                        wins.push(t);
                        used.push(t);
                    }
                }
            }
            out.push({ key: "pin:" + name, pinIndex: pi, entry: e, windows: wins, name: e ? e.name : name, icon: e ? e.icon : name });
        }

        const groups = {};
        const order = [];
        for (const t of tops) {
            if (used.indexOf(t) >= 0)
                continue;
            const k = norm(t.appId);
            if (!groups[k]) {
                groups[k] = [];
                order.push(k);
            }
            groups[k].push(t);
        }
        for (const k of order) {
            const first = groups[k][0];
            const e = DesktopEntries.heuristicLookup(first.appId);
            out.push({ key: "run:" + k, pinIndex: -1, entry: e, windows: groups[k], name: e ? e.name : first.appId, icon: e ? e.icon : first.appId });
        }
        return out;
    }

    property var items: build()

    function isActive(item) {
        for (const w of item.windows)
            if (w.activated)
                return true;
        return false;
    }

    // Launch if closed, focus if running, cycle if several windows. While a split is staged the tapped
    // app becomes the second half instead.
    function activate(item) {
        if (UI.splitStaging) {
            UI.completeSplitSelect(item);
            return;
        }
        activateNow(item);
    }

    function activateNow(item) {
        const w = item.windows;
        if (w.length > 0) {
            let next = w[0];
            for (let i = 0; i < w.length; i++) {
                if (w[i].activated) {
                    next = w[(i + 1) % w.length];
                    break;
                }
            }
            next.activate();
        } else if (item.entry) {
            Home.launch(item.entry);
        }
    }

    // Entries never shown as icons (lower-case names, substring match).
    readonly property var blockedNames: ["neovim wrapper"]
    function blocked(e) {
        const n = String(e.name || "").toLowerCase();
        for (const b of blockedNames)
            if (n.indexOf(b) >= 0)
                return true;
        return false;
    }

    function iconSource(icon) {
        const s = String(icon || "");
        if (s.startsWith("/"))
            return "file://" + s;
        if (Theme.iconDir !== "" && Theme.iconNames[s])
            return "file://" + Theme.iconDir + "/" + s + ".svg";
        return Quickshell.iconPath(s, "application-x-executable");
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

// Dock model: pinned favourites first, then any other running app.
// Running state comes from wlr-foreign-toplevel (ToplevelManager), so it needs no Hyprland IPC.
Singleton {
    id: root

    // Matched with DesktopEntries.heuristicLookup. Edit freely.
    readonly property var pinned: ["alacritty", "zen", "yazi", "nautilus"]

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

        for (const name of pinned) {
            const e = DesktopEntries.heuristicLookup(name);
            const wins = [];
            if (e) {
                for (const t of tops) {
                    if (matches(e, t.appId)) {
                        wins.push(t);
                        used.push(t);
                    }
                }
            }
            out.push({ key: "pin:" + name, entry: e, windows: wins, name: e ? e.name : name, icon: e ? e.icon : name });
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
            out.push({ key: "run:" + k, entry: e, windows: groups[k], name: e ? e.name : first.appId, icon: e ? e.icon : first.appId });
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

    // Launch if closed, focus if running, cycle if several windows.
    function activate(item) {
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
            item.entry.execute();
        }
    }

    function iconSource(icon) {
        const s = String(icon || "");
        if (s.startsWith("/"))
            return "file://" + s;
        return Quickshell.iconPath(s, "application-x-executable");
    }
}

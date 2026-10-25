pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Home screen state: icon order (all apps, flat) and widgets. Saved to ~/.config/halo/home.json.
Singleton {
    id: root

    property bool editing: false
    property bool showLabels: true
    property int density: 1 // 0 small, 1 medium, 2 large
    readonly property int cellW: [116, 132, 152][density]
    readonly property int cellH: [124, 140, 160][density]
    readonly property int tile: [68, 80, 92][density]
    property alias icons: iconModel
    property var savedOrder: []
    property var folders: ({}) // folderId -> { name, items: [eid,...] }
    property var hidden: ({}) // eid -> true, for apps removed from the home screen

    // Widget catalog. w/h = default size in units (1 unit = one square widget cell); comp = Widget<comp>.qml;
    // bare = no glass card (stickers); edge = content fills the card edge to edge; pick = what the edit-mode
    // pencil lets you choose ("photos" | "sticker" | "app" | "apps").
    // To add a widget for a new app: add a line here + a Widget<Name>.qml (declare `property var inst: null` for config).
    readonly property var widgetTypes: [
        { id: "clock", title: "Clock", w: 1, h: 1, comp: "Clock" },
        { id: "digital", title: "Digital clock", w: 2, h: 1, comp: "Digital" },
        { id: "date", title: "Date", w: 1, h: 1, comp: "Date" },
        { id: "calendar", title: "Calendar", w: 1, h: 1, comp: "Calendar" },
        { id: "weather", title: "Weather", w: 1, h: 1, comp: "Weather" },
        { id: "battery", title: "Battery", w: 1, h: 1, comp: "Battery" },
        { id: "system", title: "System", w: 1, h: 1, comp: "System" },
        { id: "media", title: "Now playing", w: 2, h: 1, comp: "Media" },
        { id: "stopwatch", title: "Stopwatch", w: 2, h: 1, comp: "Stopwatch" },
        { id: "timer", title: "Timer", w: 2, h: 1, comp: "Timer" },
        { id: "calculator", title: "Calculator", w: 2, h: 2, comp: "Calculator" },
        { id: "brightness", title: "Brightness", w: 2, h: 1, comp: "Brightness" },
        { id: "volume", title: "Volume", w: 2, h: 1, comp: "Volume" },
        { id: "toggles", title: "Quick toggles", w: 2, h: 1, comp: "Toggles" },
        { id: "year", title: "Year progress", w: 1, h: 1, comp: "Year" },
        { id: "moon", title: "Moon phase", w: 1, h: 1, comp: "Moon" },
        { id: "stack", title: "Smart stack", w: 2, h: 1, comp: "Stack", pick: "stack" },
        { id: "photo", title: "Photo frame", w: 2, h: 2, comp: "Photo", edge: true, pick: "photos" },
        { id: "sticker", title: "Sticker", w: 1, h: 1, comp: "Sticker", bare: true, edge: true, pick: "sticker" },
        { id: "shortcut", title: "App shortcut", w: 1, h: 1, comp: "Shortcut", pick: "app" },
        { id: "appsrow", title: "App row", w: 2, h: 1, comp: "AppsRow", pick: "apps" },
        { id: "notes", title: "Notes", w: 2, h: 2, comp: "Notes" },
        { id: "recentfiles", title: "Recent files", w: 2, h: 2, comp: "RecentFiles" },
        { id: "recentphotos", title: "Recent photos", w: 2, h: 1, comp: "RecentPhotos" }
    ]
    // Members of the Smart stack (swipe to flip).
    readonly property var stackItems: ["weather", "system", "date", "year", "moon", "battery"]
    // Widget types that may be put into a Smart stack (ones that need no per-instance config).
    readonly property var stackable: ["clock", "digital", "date", "calendar", "weather", "battery", "system", "media", "stopwatch", "timer", "brightness", "volume", "toggles", "year", "moon"]

    // Placed widgets: { id, type, page, fx, fy (fractions of the page), w, h (units), cfg }.
    property var winst: []
    property bool snapGrid: false // widgets snap to a half-unit grid while moving
    property string pickFor: "" // instance id being configured in the picker sheet
    readonly property string dir: Quickshell.env("HOME") + "/.config/halo"

    ListModel { id: iconModel }

    function typeOf(id) {
        for (const t of widgetTypes)
            if (t.id === id)
                return t;
        return null;
    }

    function defaultWidgets() {
        const out = [];
        let x = 0;
        for (const t of ["clock", "calendar", "media"]) {
            const ty = typeOf(t);
            out.push({ id: t + "#" + (out.length + 1), type: t, page: 0, fx: 0.08 + x * 0.21, fy: 0.0, w: ty.w, h: ty.h, cfg: {} });
            x += ty.w;
        }
        return out;
    }

    function winstById(id) {
        for (const w of winst)
            if (w.id === id)
                return w;
        return null;
    }

    function newWidgetId(type) {
        let n = 1;
        for (const w of winst) {
            const k = parseInt(String(w.id).split("#")[1]);
            if (!isNaN(k) && k >= n)
                n = k + 1;
        }
        return type + "#" + n;
    }

    function addWidget(type, page) {
        const t = typeOf(type);
        if (!t)
            return "";
        const k = winst.length % 5;
        const id = newWidgetId(type);
        winst = winst.concat([{ id: id, type: type, page: (page < 0 ? -1 : Math.max(0, page || 0)), fx: 0.1 + k * 0.03, fy: 0.05 + k * 0.03, w: t.w, h: t.h, cfg: {} }]);
        save();
        return id;
    }

    function removeWidget(id) {
        winst = winst.filter(w => w.id !== id);
        save();
    }

    function patchWidget(id, patch) {
        winst = winst.map(w => w.id === id ? Object.assign({}, w, patch) : w);
        save();
    }

    function moveWidget(id, page, fx, fy) {
        patchWidget(id, { page: page, fx: fx, fy: fy });
    }

    function resizeWidget(id, w, h) {
        patchWidget(id, { w: w, h: h });
    }

    function setCfg(id, cfg) {
        patchWidget(id, { cfg: cfg });
    }

    // ---- Folders --------------------------------------------------------------------------
    function isFolder(id) {
        return typeof id === "string" && id.indexOf("folder:") === 0;
    }

    function newFolderId() {
        return "folder:" + Date.now() + "-" + Math.floor(Math.random() * 10000);
    }

    function folderedIds() {
        const s = {};
        for (const fid in folders)
            for (const eid of folders[fid].items)
                s[eid] = true;
        return s;
    }

    function indexOfIcon(eid) {
        for (let i = 0; i < iconModel.count; i++)
            if (iconModel.get(i).eid === eid)
                return i;
        return -1;
    }

    // Drag `dragIndex`'s icon onto `targetIndex`'s icon: creates a folder, or adds to one.
    function mergeIntoFolder(dragIndex, targetIndex) {
        if (dragIndex === targetIndex || dragIndex < 0 || targetIndex < 0)
            return;
        const dragEid = iconModel.get(dragIndex).eid;
        const targetEid = iconModel.get(targetIndex).eid;
        if (dragEid === targetEid || isFolder(dragEid))
            return;

        if (isFolder(targetEid)) {
            const f = folders[targetEid];
            if (!f || f.items.indexOf(dragEid) >= 0)
                return;
            const nf = Object.assign({}, folders);
            nf[targetEid] = { name: f.name, items: f.items.concat([dragEid]) };
            folders = nf;
            iconModel.remove(dragIndex);
        } else {
            const fid = newFolderId();
            const nf = Object.assign({}, folders);
            nf[fid] = { name: "Folder", items: [targetEid, dragEid] };
            folders = nf;
            iconModel.set(targetIndex, { eid: fid });
            iconModel.remove(dragIndex);
        }
        save();
    }

    // keep === false: the icon does not go back onto the home screen (caller places it).
    function removeFromFolder(fid, eid, keep) {
        const f = folders[fid];
        if (!f)
            return;
        const items = f.items.filter(e => e !== eid);
        const nf = Object.assign({}, folders);

        if (items.length <= 1) {
            delete nf[fid];
            folders = nf;
            const idx = indexOfIcon(fid);
            if (idx >= 0) {
                if (items.length === 1)
                    iconModel.set(idx, { eid: items[0] });
                else
                    iconModel.remove(idx);
            }
        } else {
            nf[fid] = { name: f.name, items };
            folders = nf;
        }
        if (keep !== false)
            iconModel.append({ eid });
        save();
    }

    // Take an app out of its folder without adding it to the home screen (dock drop); hide = also keep it off Home.
    function leaveFolder(eid, hide) {
        for (const fid in folders)
            if (folders[fid].items.indexOf(eid) >= 0) {
                removeFromFolder(fid, eid, false);
                break;
            }
        if (hide) {
            const nh = Object.assign({}, hidden);
            nh[eid] = true;
            hidden = nh;
        }
        save();
    }

    // Reorder inside a folder (drop on another slot).
    function moveInFolder(fid, eid, rank) {
        const f = folders[fid];
        if (!f || f.items.indexOf(eid) < 0)
            return;
        const items = f.items.filter(e => e !== eid);
        items.splice(Math.max(0, Math.min(items.length, rank)), 0, eid);
        const nf = Object.assign({}, folders);
        nf[fid] = { name: f.name, items };
        folders = nf;
        save();
    }

    function renameFolder(fid, name) {
        const f = folders[fid];
        if (!f || !name)
            return;
        const nf = Object.assign({}, folders);
        nf[fid] = { name, items: f.items };
        folders = nf;
        save();
    }

    // Drag-to-trash / "Remove from Home Screen": drops the icon, not the app itself. A folder
    // drops its whole contents back into the hidden set (they stay out of Home until re-added).
    function hideIconAt(index) {
        if (index < 0 || index >= iconModel.count)
            return;
        const eid = iconModel.get(index).eid;
        const nh = Object.assign({}, hidden);
        if (isFolder(eid)) {
            const f = folders[eid];
            const nf = Object.assign({}, folders);
            delete nf[eid];
            folders = nf;
            if (f)
                for (const m of f.items)
                    nh[m] = true;
        } else {
            nh[eid] = true;
        }
        hidden = nh;
        iconModel.remove(index);
        save();
    }

    // Used by the app launcher's "Add to Home Screen" action.
    function addToHome(eid) {
        const nh = Object.assign({}, hidden);
        delete nh[eid];
        hidden = nh;
        if (indexOfIcon(eid) < 0)
            iconModel.append({ eid });
        save();
    }

    // Library drag: put an app on the home screen at `index` (un-hides it, takes it out of a folder, moves it if already there).
    function addToHomeAt(eid, index) {
        const nh = Object.assign({}, hidden);
        delete nh[eid];
        hidden = nh;
        for (const fid in folders)
            if (folders[fid].items.indexOf(eid) >= 0) {
                removeFromFolder(fid, eid);
                break;
            }
        const cur = indexOfIcon(eid);
        if (cur >= 0) {
            moveIcon(cur, Math.max(0, Math.min(iconModel.count - 1, index)));
        } else {
            iconModel.insert(Math.max(0, Math.min(iconModel.count, index)), { eid });
        }
        save();
    }

    // ---- App library (last page): every app grouped by freedesktop category --------------------
    readonly property var libOrder: ["Productivity", "Creativity", "Media", "Internet", "Games", "Developer", "Utilities", "System", "Other"]

    function catOf(e) {
        const c = e.categories || [];
        const has = k => c.indexOf(k) >= 0;
        if (has("Game"))
            return "Games";
        if (has("Development"))
            return "Developer";
        if (has("WebBrowser") || has("Network"))
            return "Internet";
        if (has("Office"))
            return "Productivity";
        if (has("Graphics") || has("Photography"))
            return "Creativity";
        if (has("AudioVideo") || has("Audio") || has("Video") || has("Player"))
            return "Media";
        if (has("Settings") || has("System") || has("Monitor"))
            return "System";
        if (has("Utility"))
            return "Utilities";
        return "Other";
    }

    function buildLibrary() {
        const by = {};
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay || Apps.blocked(e))
                continue;
            const c = catOf(e);
            if (!by[c])
                by[c] = [];
            by[c].push(e);
        }
        const out = [];
        for (const c of libOrder) {
            if (!by[c])
                continue;
            by[c].sort((a, b) => String(a.name).localeCompare(String(b.name)));
            out.push({ title: c, items: by[c] });
        }
        return out;
    }

    property var libCats: buildLibrary()

    function entry(id) {
        if (isFolder(id)) {
            const f = folders[id];
            return f ? { isFolder: true, id, name: f.name, items: f.items } : null;
        }
        return DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id);
    }

    // Visible apps: saved order first (folders kept as-is), then the rest alphabetically.
    // Apps already inside a folder are excluded from the top-level list.
    function sync() {
        if (editing)
            return;
        const byId = {};
        const names = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay || Apps.blocked(e))
                continue;
            byId[e.id] = e;
            names.push(e);
        }
        names.sort((a, b) => String(a.name).localeCompare(String(b.name)));
        const inFolder = folderedIds();
        const ids = [];
        const seen = {};
        for (const id of savedOrder) {
            if (seen[id] || inFolder[id] || hidden[id])
                continue;
            if (isFolder(id)) {
                if (folders[id]) {
                    ids.push(id);
                    seen[id] = true;
                }
            } else if (byId[id]) {
                ids.push(id);
                seen[id] = true;
            }
        }
        for (const e of names) {
            if (!seen[e.id] && !inFolder[e.id] && !hidden[e.id]) {
                ids.push(e.id);
                seen[e.id] = true;
            }
        }
        let same = ids.length === iconModel.count;
        for (let i = 0; same && i < ids.length; i++)
            same = iconModel.get(i).eid === ids[i];
        if (same)
            return;
        iconModel.clear();
        for (const id of ids)
            iconModel.append({ eid: id });
    }

    function reset() {
        editing = false;
        savedOrder = [];
        winst = defaultWidgets();
        folders = ({});
        hidden = ({});
        showLabels = true;
        density = 1;
        iconModel.clear();
        sync();
        save();
    }

    // Tablet: every app gets its own fresh workspace; the "home" workspace stays empty (desktop).
    property var pendingLaunch: null

    function launch(entry) {
        if (!entry)
            return;
        if (typeof UI !== "undefined" && UI.splitStaging) {
            UI.completeSplitSelect({ key: "launch:" + entry.id, pinIndex: -1, entry: entry, windows: [], name: entry.name, icon: entry.icon });
            return;
        }
        if (typeof Mode !== "undefined" && Mode.tablet) {
            pendingLaunch = entry;
            Quickshell.execDetached(["hyprctl", "eval", "new_ws()"]);
            launchTimer.restart();
        } else {
            entry.execute();
        }
    }

    Timer {
        id: launchTimer
        interval: 140
        onTriggered: {
            if (root.pendingLaunch)
                root.pendingLaunch.execute();
            root.pendingLaunch = null;
        }
    }

    function moveIcon(from, to) {
        if (from === to || from < 0 || to < 0 || from >= iconModel.count || to >= iconModel.count)
            return;
        iconModel.move(from, to, 1);
    }

    function save() {
        const ids = [];
        for (let i = 0; i < iconModel.count; i++)
            ids.push(iconModel.get(i).eid);
        savedOrder = ids;
        file.setText(JSON.stringify({ order: ids, winst: winst, snap: snapGrid, labels: showLabels, density: density, folders: folders, hidden: hidden }));
    }

    function apply(raw) {
        try {
            const p = JSON.parse(raw);
            if (Array.isArray(p.order))
                savedOrder = p.order;
            if (Array.isArray(p.winst)) {
                winst = p.winst.filter(w => w && typeOf(w.type) !== null);
            } else if (Array.isArray(p.widgets)) {
                // Old format: one widget per type in a single row.
                const out = [];
                let x = 0;
                for (const tid of p.widgets) {
                    const ty = typeOf(tid);
                    if (!ty)
                        continue;
                    const w = (p.sizes && p.sizes[tid]) ? p.sizes[tid] : ty.w;
                    out.push({ id: tid + "#" + (out.length + 1), type: tid, page: 0, fx: 0.08 + x * 0.21, fy: 0.0, w: w, h: ty.h, cfg: {} });
                    x += w;
                }
                winst = out;
            } else {
                winst = defaultWidgets();
            }
            if (typeof p.snap === "boolean")
                snapGrid = p.snap;
            if (typeof p.labels === "boolean")
                showLabels = p.labels;
            if (typeof p.density === "number" && p.density >= 0 && p.density <= 2)
                density = p.density;
            if (p.folders && typeof p.folders === "object")
                folders = p.folders;
            if (p.hidden && typeof p.hidden === "object")
                hidden = p.hidden;
        } catch (e) {}
        sync();
    }

    FileView {
        id: file
        path: root.dir + "/home.json"
        atomicWrites: true
        onLoaded: root.apply(text())
        onLoadFailed: root.apply("")
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.sync();
        }
    }

    Component.onCompleted: {
        winst = defaultWidgets();
        Quickshell.execDetached(["mkdir", "-p", root.dir]);
    }
}

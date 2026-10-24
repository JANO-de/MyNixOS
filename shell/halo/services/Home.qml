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
    property var widgets: ["clock", "calendar", "media"]
    property var savedOrder: []

    // Widget row holds at most 4 units.
    readonly property int maxSpan: 4
    readonly property var widgetTypes: [
        { id: "clock", title: "Clock", span: 1 },
        { id: "calendar", title: "Calendar", span: 1 },
        { id: "battery", title: "Battery", span: 1 },
        { id: "media", title: "Now playing", span: 2 }
    ]
    readonly property string dir: Quickshell.env("HOME") + "/.config/halo"

    ListModel { id: iconModel }

    function typeOf(id) {
        for (const t of widgetTypes)
            if (t.id === id)
                return t;
        return null;
    }

    function usedSpan() {
        let n = 0;
        for (const id of widgets) {
            const t = typeOf(id);
            if (t)
                n += t.span;
        }
        return n;
    }

    function addable() {
        const out = [];
        const free = maxSpan - usedSpan();
        for (const t of widgetTypes)
            if (widgets.indexOf(t.id) < 0 && t.span <= free)
                out.push(t);
        return out;
    }

    function addWidget(id) {
        const t = typeOf(id);
        if (!t || widgets.indexOf(id) >= 0 || usedSpan() + t.span > maxSpan)
            return;
        widgets = widgets.concat([id]);
        save();
    }

    function removeWidget(id) {
        widgets = widgets.filter(w => w !== id);
        save();
    }

    function entry(id) {
        return DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id);
    }

    // Visible apps: saved order first, then the rest alphabetically.
    function sync() {
        if (editing)
            return;
        const byId = {};
        const names = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay)
                continue;
            byId[e.id] = e;
            names.push(e);
        }
        names.sort((a, b) => String(a.name).localeCompare(String(b.name)));
        const ids = [];
        const seen = {};
        for (const id of savedOrder) {
            if (byId[id] && !seen[id]) {
                ids.push(id);
                seen[id] = true;
            }
        }
        for (const e of names) {
            if (!seen[e.id]) {
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
        widgets = ["clock", "calendar", "media"];
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
        file.setText(JSON.stringify({ order: ids, widgets: widgets, labels: showLabels, density: density }));
    }

    function apply(raw) {
        try {
            const p = JSON.parse(raw);
            if (Array.isArray(p.order))
                savedOrder = p.order;
            if (Array.isArray(p.widgets))
                widgets = p.widgets.filter(w => typeOf(w) !== null);
            if (typeof p.labels === "boolean")
                showLabels = p.labels;
            if (typeof p.density === "number" && p.density >= 0 && p.density <= 2)
                density = p.density;
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

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.dir])
}

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Halo Files: Dolphin features (tabs, split view, details/columns, undo/redo, archives, trash, drives, info panel)
// in a Material 3 Expressive look (drawer, tonal surfaces, pill chips; Yazi-style columns).
FloatingWindow {
    id: win
    title: "Files"
    color: AppTheme.bg
    implicitWidth: 1180
    implicitHeight: 760

    readonly property string home: AppTheme.home
    readonly property string trashRoot: home + "/.local/share/Trash"
    readonly property string trashFiles: trashRoot + "/files"
    readonly property string sd: Qt.resolvedUrl("scripts/").toString().replace("file://", "")
    readonly property bool wide: width >= 900
    readonly property var places: [
        { n: "Home", ico: "home", p: home, icon: "user-home" }, { n: "Documents", ico: "doc", p: home + "/Documents", icon: "folder-documents" },
        { n: "Downloads", ico: "download", p: home + "/Downloads", icon: "folder-download" }, { n: "Pictures", ico: "image", p: home + "/Pictures", icon: "folder-pictures" },
        { n: "Music", ico: "music", p: home + "/Music", icon: "folder-music" }, { n: "Videos", ico: "video", p: home + "/Videos", icon: "folder-videos" },
        { n: "Trash", ico: "trash", p: trashFiles, icon: "user-trash" }
    ]

    // settings (saved to ~/.config/halo/files.json)
    property string view: "grid"     // grid | list | columns
    property int zoom: 72
    property bool showHidden: false
    property string sortKey: "name"
    property bool sortDesc: false
    property bool singleClick: true
    property bool info: false
    property bool sidebarOpen: true
    property var bookmarks: []
    readonly property bool showInfo: (info || view === "columns") && width >= 800

    // state
    property int cur: 0
    property int nextUid: 2
    property var clipPaths: []
    property bool cutMode: false
    property var undoStack: []
    property var redoStack: []
    property var drives: []
    property string lsText: ""
    property var dlg: null
    property var props: null
    property string owPath: ""
    property string owQuery: ""
    property var mctx: ({})
    property bool pathEditing: false
    property var tried: ({})
    property string drivesJson: ""
    property var ap: null
    readonly property bool typing: filterIn.activeFocus || dlg !== null || props !== null || owPath !== "" || pathEditing

    readonly property string statusText: {
        const p = ap;
        if (!p)
            return "";
        if (p.isPc)
            return drives.length + " drives";
        const s = p.sel.length;
        if (s > 0) {
            let b = 0;
            for (const e of p.selEntries())
                if (!e.dir)
                    b += e.size;
            return s + " selected" + (b > 0 ? " \u00b7 " + Fx.human(b) : "");
        }
        return p.entries.length + (p.searching ? " results" : " items");
    }

    onViewChanged: saveSoon()
    onZoomChanged: saveSoon()
    onShowHiddenChanged: saveSoon()
    onSortKeyChanged: saveSoon()
    onSortDescChanged: saveSoon()
    onSingleClickChanged: saveSoon()
    onInfoChanged: saveSoon()
    onBookmarksChanged: saveSoon()

    ListModel { id: tabs }

    // ---- helpers -----------------------------------------------------------------------------
    function activeTab() { return tabRep.itemAt(cur); }
    function activePane() {
        const t = tabRep.itemAt(cur);
        return t ? t.active : null;
    }
    function otherPane() {
        const t = tabRep.itemAt(cur);
        return t ? t.other : null;
    }
    function focusPane(p) {
        const t = tabRep.itemAt(cur);
        if (t && t.split)
            t.activeIdx = (p === t.second ? 1 : 0);
        ap = activePane();
    }
    function goActive(p) {
        const a = activePane();
        if (a)
            a.go(p);
    }
    function setTabTitle(uid, t) {
        for (let i = 0; i < tabs.count; i++)
            if (tabs.get(i).uid === uid)
                tabs.setProperty(i, "title", t);
    }
    function newTab(p) {
        const a = activePane();
        tabs.append({ uid: nextUid++, title: "", start: p || (a && !a.isPc ? a.path : home) });
        cur = tabs.count - 1;
        ap = activePane();
    }
    function closeTab(i) {
        if (tabs.count <= 1) {
            Qt.quit();
            return;
        }
        tabs.remove(i);
        cur = Math.min(cur, tabs.count - 1);
        ap = activePane();
    }
    function toggleSplit() {
        const t = activeTab();
        if (t)
            t.split = !t.split;
        ap = activePane();
    }
    function filterClear() {
        filterIn.text = "";
    }
    function refreshAll() {
        for (let i = 0; i < tabs.count; i++) {
            const t = tabRep.itemAt(i);
            if (t) {
                t.first.refresh();
                if (t.split)
                    t.second.refresh();
            }
        }
    }
    function toast(m) {
        toastText.text = m;
        toastBox.show = true;
        toastTimer.restart();
    }
    function exec(cmd, cb, quiet) {
        const j = jobC.createObject(win, { command: cmd, cb: cb || null, quiet: !!quiet });
        j.running = true;
    }
    function sh(script, args) {
        return ["bash", sd + script].concat(args);
    }
    function statOf(path, deep, cb) {
        exec(["bash", sd + "stat.sh", path, deep ? "deep" : ""], cb, true);
    }
    function openFile(p) {
        Quickshell.execDetached(["xdg-open", p]);
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/.cache/halo\"; f=\"$HOME/.cache/halo/recent-files\"; { printf '%s\\n' \"$1\"; grep -vxF -- \"$1\" \"$f\" 2>/dev/null; } | head -20 > \"$f.tmp\" && mv \"$f.tmp\" \"$f\"", "sh", p]);
    }
    function ask(title, text, ok, fn) {
        dlg = { kind: "prompt", title: title, text: text, ok: ok, fn: fn };
        Qt.callLater(() => { dlgIn.text = text; dlgIn.forceActiveFocus(); dlgIn.selectAll(); });
    }
    function confirm(title, msg, ok, fn) {
        dlg = { kind: "confirm", title: title, text: msg, ok: ok, fn: fn };
    }

    // ---- file operations (with undo / redo) --------------------------------------------------
    function pushUndo(e) {
        undoStack = undoStack.concat([e]);
        redoStack = [];
    }
    function undo() {
        if (undoStack.length === 0) {
            toast("Nothing to undo");
            return;
        }
        const e = undoStack[undoStack.length - 1];
        undoStack = undoStack.slice(0, -1);
        e.bwd();
        redoStack = redoStack.concat([e]);
        toast("Undo: " + e.label);
    }
    function redo() {
        if (redoStack.length === 0) {
            toast("Nothing to redo");
            return;
        }
        const e = redoStack[redoStack.length - 1];
        redoStack = redoStack.slice(0, -1);
        e.fwd();
        undoStack = undoStack.concat([e]);
        toast("Redo: " + e.label);
    }
    function pairs(out) {
        return out.trim() === "" ? [] : out.trim().split("\n").map(l => l.split("\t"));
    }
    property bool cpBusy: false
    property real cpTotal: 0
    property real cpDone: 0
    property var cpProc: null
    function runCp(mode, dst, srcs, done) {
        if (cpBusy) {
            toast("Another copy is running");
            return;
        }
        cpBusy = true;
        cpTotal = 0;
        cpDone = 0;
        const j = cpC.createObject(win, { command: sh("cpmvp.sh", [mode, dst].concat(srcs)), fin: done });
        cpProc = j;
        j.running = true;
    }
    Component {
        id: cpC
        Process {
            id: cp
            property var fin: null
            property var pr: []
            stdout: SplitParser {
                onRead: line => {
                    const f = line.split("\t");
                    if (f[0] === "T")
                        win.cpTotal = Number(f[1]);
                    else if (f[0] === "P")
                        win.cpDone = Number(f[1]);
                    else if (f[0] === "D" && f.length >= 3)
                        cp.pr = cp.pr.concat([[f[1], f[2]]]);
                }
            }
            onExited: code => {
                win.cpBusy = false;
                win.cpProc = null;
                if (cp.fin)
                    cp.fin(cp.pr);
                if (code === 130 || code === 143)
                    win.toast("Cancelled");
                else if (code !== 0)
                    win.toast("Operation failed");
                win.refreshAll();
                cp.destroy(1500);
            }
        }
    }
    function cancelCp() {
        if (cpProc)
            cpProc.running = false;
    }
    function copyMove(mode, srcs, dst) {
        if (srcs.length === 0)
            return;
        const e = { label: mode === "cp" ? "Copy" : "Move", pr: [] };
        e.fwd = () => runCp(mode, dst, srcs, pr => { e.pr = pr; });
        e.bwd = () => {
            if (mode === "cp")
                exec(["rm", "-rf", "--"].concat(e.pr.map(p => p[1])));
            else
                exec(sh("reverse.sh", [].concat(...e.pr.map(p => [p[1], p[0]]))));
        };
        e.fwd();
        pushUndo(e);
    }

    // ---- drag and drop (mouse / stylus) ------------------------------------------------------
    property var dragPaths: []
    property bool dragOn: false
    property real dragX: 0
    property real dragY: 0
    function dragStart(paths) {
        dragPaths = paths;
        dragOn = true;
    }
    function dragMove(gx, gy) {
        dragX = gx;
        dragY = gy;
        const t = activeTab();
        if (!t)
            return;
        const hit = dropTarget(gx, gy);
        for (const p of [t.first, t.second])
            p.dropPath = hit && hit.pane === p ? hit.dst : "";
    }
    function dragEnd(gx, gy, copy) {
        dragOn = false;
        const t = activeTab();
        if (t)
            for (const p of [t.first, t.second])
                p.dropPath = "";
        const hit = dropTarget(gx, gy);
        if (!hit)
            return;
        const srcs = dragPaths.filter(s => s !== hit.dst && hit.dst.indexOf(s + "/") !== 0);
        copyMove(copy ? "cp" : "mv", srcs, hit.dst);
        hit.pane.sel = [];
    }
    function dropTarget(gx, gy) {
        const t = activeTab();
        if (!t)
            return null;
        for (const p of (t.split ? [t.first, t.second] : [t.first])) {
            const q = p.mapFromItem(null, gx, gy);
            if (q.x < 0 || q.y < 0 || q.x > p.width || q.y > p.height)
                continue;
            if (p.isPc || p.inTrash || p.path === "")
                return null;
            const fp = p.folderAt(gx, gy);
            return { pane: p, dst: fp !== "" && dragPaths.indexOf(fp) < 0 ? fp : p.path };
        }
        return null;
    }
    function paste() {
        const p = activePane();
        if (!p || p.isPc || p.inTrash || clipPaths.length === 0)
            return;
        copyMove(cutMode ? "mv" : "cp", clipPaths, p.path);
        if (cutMode)
            clipPaths = [];
    }
    function setClip(cut) {
        const p = activePane();
        if (!p || p.sel.length === 0)
            return;
        clipPaths = p.sel.slice();
        cutMode = cut;
        toast((cut ? "Cut " : "Copied ") + clipPaths.length);
        p.sel = [];
    }
    function exists(p, name) {
        return p.raw.some(x => x.name === name);
    }
    function rename(old, name) {
        const p = activePane();
        const dst = Fx.dirOf(old) + "/" + name;
        if (name === "" || dst === old)
            return;
        if (p && exists(p, name)) {
            toast("\u201c" + name + "\u201d already exists");
            return;
        }
        const e = { label: "Rename", fwd: () => exec(["mv", "-n", "--", old, dst]), bwd: () => exec(["mv", "-n", "--", dst, old]) };
        e.fwd();
        pushUndo(e);
        if (p)
            p.sel = [];
    }
    function create(isDir, name) {
        const p = activePane();
        name = name.trim().replace(/\//g, "");
        if (!p || name === "")
            return;
        if (exists(p, name)) {
            toast("\u201c" + name + "\u201d already exists");
            return;
        }
        const f = p.path + "/" + name;
        const e = isDir ? { label: "New folder", fwd: () => exec(["mkdir", "-p", "--", f]), bwd: () => exec(["rmdir", "--", f]) } : { label: "New file", fwd: () => exec(["touch", "--", f]), bwd: () => exec(["rm", "-f", "--", f]) };
        e.fwd();
        pushUndo(e);
    }
    function trashSel(paths) {
        if (paths.length === 0)
            return;
        const e = { label: "Trash", pr: [] };
        e.fwd = () => exec(sh("trash.sh", paths), out => { e.pr = pairs(out); });
        e.bwd = () => exec(sh("restore.sh", e.pr.map(p => p[1])));
        e.fwd();
        pushUndo(e);
        const p = activePane();
        if (p)
            p.sel = [];
    }
    function restoreSel(paths) {
        exec(sh("restore.sh", paths.map(p => Fx.base(p))));
        const p = activePane();
        if (p)
            p.sel = [];
    }
    function deleteForever(paths) {
        confirm("Delete permanently?", paths.length + " item(s) will be gone for good.", "Delete", () => {
            exec(["rm", "-rf", "--"].concat(paths));
            const p = activePane();
            if (p)
                p.sel = [];
        });
    }
    function emptyTrash() {
        confirm("Empty Trash?", "Everything in the Trash will be deleted.", "Empty", () => exec(sh("emptytrash.sh", [])));
    }
    function compress(fmt, base, paths) {
        const p = activePane();
        const ext = { zip: ".zip", tgz: ".tar.gz", txz: ".tar.xz", "7z": ".7z" }[fmt];
        const out = base.trim() + ext;
        if (!p || base.trim() === "")
            return;
        if (exists(p, out)) {
            toast("\u201c" + out + "\u201d already exists");
            return;
        }
        const e = { label: "Compress", made: "" };
        e.fwd = () => {
            toast("Compressing\u2026");
            exec(sh("compress.sh", [p.path, out, fmt].concat(paths.map(x => Fx.base(x)))), t => { e.made = t.trim(); toast(e.made !== "" ? "Created " + out : "Compression failed"); });
        };
        e.bwd = () => { if (e.made !== "") exec(["rm", "-f", "--", e.made]); };
        e.fwd();
        pushUndo(e);
        p.sel = [];
    }
    function extract(path) {
        const e = { label: "Extract", made: "" };
        e.fwd = () => {
            toast("Extracting\u2026");
            exec(sh("extract.sh", [path]), t => { e.made = t.trim(); toast(e.made !== "" ? "Extracted" : "Extraction failed"); });
        };
        e.bwd = () => { if (e.made !== "") exec(["rm", "-rf", "--", e.made]); };
        e.fwd();
        pushUndo(e);
    }
    function showProps(path, name) {
        props = { name: name, rows: [["Path", path]] };
        statOf(path, true, t => {
            const l = t.split("\n");
            if (l.length < 4)
                return;
            const f = l[0].split("|");
            const dir = f[0].indexOf("directory") >= 0;
            props = { name: name, rows: [["Path", path], ["Type", f[0] + " \u00b7 " + l[1]], [dir ? "Total size" : "Size", Fx.human(parseInt(dir ? l[3] : f[4]))], dir ? ["Items", l[2]] : ["", ""], ["Modified", (f[3] || "").substring(0, 19)], ["Permissions", f[1] + "  " + f[2]]].filter(r => r[0] !== "") };
        });
    }

    // ---- drives ------------------------------------------------------------------------------
    function refreshDrives() {
        lsblk.running = false;
        lsblk.running = true;
    }
    function parseDrives(ls, df) {
        const use = {};
        for (const l of df.split("\n").slice(1)) {
            const m = /^(.+?)\s+(\d+)\s+(\d+)\s*$/.exec(l);
            if (m)
                use[m[1]] = { total: +m[2], used: +m[3] };
        }
        const out = [];
        const skip = ["swap", "crypto_LUKS", "LVM2_member", "linux_raid_member", "squashfs"];
        const walk = (n, hot) => {
            const h = hot || n.rm === true || n.rm === "1" || n.hotplug === true || n.hotplug === "1";
            const mps = (n.mountpoints || (n.mountpoint ? [n.mountpoint] : [])).filter(x => x);
            const fs = n.fstype || "";
            if (fs !== "" && skip.indexOf(fs) < 0 && n.type !== "loop") {
                const mp = mps.length ? mps[0] : "";
                if (mp === "" || mp === "/" || /^\/(home|run\/media|media|mnt)(\/|$)/.test(mp)) {
                    const u = use[mp] || { total: +n.size || 0, used: 0 };
                    out.push({ path: n.path || ("/dev/" + n.name), title: mp === "/" ? "Filesystem" : (n.label || Fx.base(n.path || n.name)), mount: mp, fs: fs, total: u.total, used: u.used, removable: h });
                }
            }
            for (const c of (n.children || []))
                walk(c, h);
        };
        try {
            for (const n of JSON.parse(ls).blockdevices)
                walk(n, false);
        } catch (e) {}
        const js = JSON.stringify(out);
        if (js === drivesJson)
            return;
        drivesJson = js;
        drives = out;
        for (const d of out)
            if (d.removable && d.mount === "" && !tried[d.path]) {
                tried[d.path] = true;
                mountDrive(d, null);
            }
    }
    function mountDrive(d, pane) {
        exec(["udisksctl", "mount", "-b", d.path], out => {
            const m = /at (.+?)\.?\s*$/m.exec(out);
            refreshDrives();
            if (m && pane)
                pane.go(m[1]);
            else if (m)
                toast("Mounted " + d.title);
            else if (pane)
                toast("Could not mount");
        }, true);
    }
    function unmountDrive(d) {
        exec(["udisksctl", "unmount", "-b", d.path], () => refreshDrives(), true);
    }

    // ---- settings persistence ----------------------------------------------------------------
    function saveSoon() {
        saveT.restart();
    }
    FileView {
        id: cfg
        path: AppTheme.home + "/.config/halo/files.json"
        atomicWrites: true
        onLoaded: {
            try {
                const j = JSON.parse(text());
                if (j.view)
                    win.view = j.view;
                if (j.zoom)
                    win.zoom = j.zoom;
                if (j.sortKey)
                    win.sortKey = j.sortKey;
                win.showHidden = !!j.showHidden;
                win.sortDesc = !!j.sortDesc;
                win.info = !!j.info;
                if (j.singleClick !== undefined)
                    win.singleClick = !!j.singleClick;
                if (j.bookmarks)
                    win.bookmarks = j.bookmarks;
            } catch (e) {}
        }
    }
    Timer {
        id: saveT
        interval: 700
        onTriggered: cfg.setText(JSON.stringify({ view: win.view, zoom: win.zoom, showHidden: win.showHidden, sortKey: win.sortKey, sortDesc: win.sortDesc, info: win.info, singleClick: win.singleClick, bookmarks: win.bookmarks }))
    }
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            const a = win.activePane();
            if (a !== win.ap)
                win.ap = a;
        }
    }
    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: win.refreshDrives()
    }
    Process {
        id: lsblk
        command: ["lsblk", "-J", "-b", "-o", "NAME,PATH,LABEL,SIZE,FSTYPE,MOUNTPOINTS,TYPE,RM,HOTPLUG"]
        stdout: StdioCollector {
            onStreamFinished: {
                win.lsText = text;
                dfp.running = false;
                dfp.running = true;
            }
        }
    }
    Process {
        id: dfp
        command: ["df", "-B1", "--output=target,size,used"]
        stdout: StdioCollector { onStreamFinished: win.parseDrives(win.lsText, text) }
    }
    Component {
        id: jobC
        Process {
            id: jp
            property var cb: null
            property bool quiet: false
            stdout: StdioCollector {
                onStreamFinished: {
                    if (jp.cb)
                        jp.cb(text);
                    if (!jp.quiet)
                        win.refreshAll();
                    jp.destroy(1500);
                }
            }
            onExited: code => {
                if (code !== 0 && !jp.quiet)
                    win.toast("Operation failed");
            }
        }
    }
    Component.onCompleted: {
        tabs.append({ uid: 1, title: "Home", start: home });
        refreshDrives();
        Qt.callLater(() => { win.ap = win.activePane(); });
    }

    // ---- menus (modelled on Dolphin's context menus) -----------------------------------------
    function mi(id, label, ico, o) {
        return Object.assign({ id: id, label: label, ico: ico }, o || {});
    }
    readonly property var sortSub: [
        { id: "s:name", label: "Name" + (sortKey === "name" ? "  \u2713" : "") }, { id: "s:size", label: "Size" + (sortKey === "size" ? "  \u2713" : "") },
        { id: "s:date", label: "Modified" + (sortKey === "date" ? "  \u2713" : "") }, { id: "s:type", label: "Type" + (sortKey === "type" ? "  \u2713" : "") },
        { sep: true }, { id: "s:desc", label: "Descending" + (sortDesc ? "  \u2713" : "") }
    ]
    readonly property var viewSub: [
        { id: "v:grid", ico: "grid", label: "Icons" + (view === "grid" ? "  \u2713" : "") }, { id: "v:list", ico: "list", label: "Details" + (view === "list" ? "  \u2713" : "") },
        { id: "v:columns", ico: "columns", label: "Columns" + (view === "columns" ? "  \u2713" : "") }, { sep: true },
        { id: "zoomin", ico: "zoomin", label: "Zoom in" }, { id: "zoomout", ico: "zoomout", label: "Zoom out" }, { sep: true },
        { id: "hidden", ico: "eye", label: "Show hidden files" + (showHidden ? "  \u2713" : "") }, { id: "info", ico: "info", label: "Information panel" + (info ? "  \u2713" : "") },
        { id: "split", ico: "split", label: "Split view" }, { id: "single", ico: "select", label: "Single-click to open" + (singleClick ? "  \u2713" : "") }
    ]
    readonly property var selSub: [
        { id: "selall", ico: "select", label: "Select all" }, { id: "selnone", label: "Select none" }, { id: "invert", label: "Invert selection" }, { id: "selmatch", label: "Select matching\u2026" }
    ]
    function itemMenu(pane, x, y) {
        const es = pane.selEntries();
        const n = es.length;
        const one = n === 1 ? es[0] : null;
        const t = activeTab();
        const sp = t && t.split;
        const allArch = n > 0 && es.every(e => Fx.isArchive(e.name));
        const img = one && Fx.kind(one) === "image";
        const m = [];
        if (pane.inTrash) {
            m.push(mi("restore", "Restore", "restore"), mi("delperm", "Delete permanently", "trash", { danger: true }), { sep: true }, mi("props", "Properties", "info"));
        } else {
            m.push(mi("open", n > 1 ? "Open " + n + " items" : "Open", "open"));
            if (one && !one.dir)
                m.push(mi("openwith", "Open with\u2026", "open"));
            if (one && one.dir)
                m.push(mi("newtab", "Open in new tab", "plus"), mi("terminal", "Open terminal here", "terminal"));
            if (one && one.dir && sp)
                m.push(mi("inother", "Open in other pane", "split"));
            m.push({ sep: true }, mi("cut", "Cut", "cut"), mi("copy", "Copy", "copy"));
            if (one && one.dir && clipPaths.length > 0)
                m.push(mi("pasteinto", "Paste into folder", "paste"));
            m.push(mi("dup", "Duplicate here", "copy"), mi("rename", n > 1 ? "Rename " + n + " items\u2026" : "Rename\u2026", "edit"));
            m.push({ sep: true }, mi("copyto", "Copy to\u2026", "copy"), mi("moveto", "Move to\u2026", "fwd"));
            if (sp)
                m.push(mi("copyother", "Copy to other pane", "split"), mi("moveother", "Move to other pane", "split"));
            if (one)
                m.push(mi("link", "Create link here", "link"));
            m.push({ sep: true }, { label: "Compress", ico: "compress", sub: [mi("cz:zip", ".zip"), mi("cz:tgz", ".tar.gz"), mi("cz:txz", ".tar.xz"), mi("cz:7z", ".7z")] });
            if (allArch)
                m.push(mi("extract", "Extract here", "extract"));
            m.push({ sep: true }, mi("copypath", "Copy location", "copy"));
            if (one && one.dir)
                m.push(mi("bookmark", "Add to places", "star"));
            if (img)
                m.push(mi("wallpaper", "Add to wallpapers", "image"));
            if (one && !one.dir)
                m.push(mi("checksum", "SHA-256 checksum", "hash"));
            m.push(mi("perms", "Permissions\u2026", "lock"), mi("props", "Properties", "info"), { sep: true }, mi("trash", "Move to Trash", "trash", { danger: true }), mi("delperm", "Delete permanently", "close", { danger: true }));
        }
        mctx = { pane: pane, x: x, y: y };
        ctxMenu.popup(x, y, m);
    }
    function bgMenu(pane, x, y) {
        let m;
        if (pane.inTrash)
            m = [mi("emptytrash", "Empty Trash", "trash", { danger: true }), mi("restoreall", "Restore all", "restore"), { sep: true }, { label: "Select", ico: "select", sub: selSub }, { label: "Sort by", ico: "sort", sub: sortSub }, mi("refresh", "Refresh", "refresh")];
        else
            m = [{ label: "Create new", ico: "plus", sub: [mi("newfolder", "Folder", "newfolder"), mi("newfile", "Text file", "newfile"), mi("newlink", "Link to\u2026", "link")] },
                 mi("paste", "Paste", "paste", { disabled: clipPaths.length === 0 }), { sep: true },
                 { label: "Select", ico: "select", sub: selSub }, { label: "View", ico: "grid", sub: viewSub }, { label: "Sort by", ico: "sort", sub: sortSub }, { sep: true },
                 mi("terminal", "Open terminal here", "terminal"), mi("bookmark", "Add to places", "star"), mi("refresh", "Refresh", "refresh"), mi("folderprops", "Properties", "info")];
        mctx = { pane: pane, x: x, y: y };
        ctxMenu.popup(x, y, m);
    }
    function moreMenu(x, y) {
        const p = activePane();
        const m = [{ label: "View", ico: "grid", sub: viewSub }, { label: "Sort by", ico: "sort", sub: sortSub }, { label: "Select", ico: "select", sub: selSub }, { sep: true },
                   mi("undo", "Undo", "restore", { disabled: undoStack.length === 0 }), mi("redo", "Redo", "redo", { disabled: redoStack.length === 0 }), { sep: true },
                   mi("newtab", "New tab", "plus"), mi("terminal", "Open terminal here", "terminal"), mi("refresh", "Refresh", "refresh")];
        if (p && p.inTrash)
            m.push({ sep: true }, mi("emptytrash", "Empty Trash", "trash", { danger: true }));
        mctx = { pane: p, x: x, y: y };
        ctxMenu.popup(x, y, m);
    }
    function placeMenu(path, x, y) {
        mctx = { pane: activePane(), p: path };
        const m = [mi("placetab", "Open in new tab", "plus")];
        if (path === trashFiles)
            m.push(mi("emptytrash", "Empty Trash", "trash", { danger: true }));
        ctxMenu.popup(x, y, m);
    }
    function driveMenu(d, x, y) {
        mctx = { pane: activePane(), drive: d };
        const m = [];
        if (d.mount !== "")
            m.push(mi("drvopen", "Open", "open"), mi("drvtab", "Open in new tab", "plus"));
        else
            m.push(mi("drvmount", "Mount", "sd"));
        if (d.mount.indexOf("/run/media") === 0)
            m.push(mi("drvunmount", "Unmount", "eject"));
        ctxMenu.popup(x, y, m);
    }
    function tabMenu(i, x, y) {
        mctx = { pane: activePane(), tab: i };
        ctxMenu.popup(x, y, [mi("tabdup", "Duplicate tab", "copy"), mi("tabclose", "Close tab", "close"), mi("tabothers", "Close other tabs", "close", { disabled: tabs.count < 2 })]);
    }
    function terminalAt(path) {
        Quickshell.execDetached(["sh", "-c", "cd \"$1\" || exit; for t in foot kitty alacritty wezterm konsole xterm; do command -v $t >/dev/null && exec $t; done", "sh", path]);
    }
    function showPropsMulti(es) {
        let b = 0, f = 0, d = 0;
        for (const e of es) {
            if (e.dir)
                d++;
            else {
                f++;
                b += e.size;
            }
        }
        props = { name: es.length + " items", rows: [["Files", "" + f], ["Folders", "" + d], ["Total size (files)", Fx.human(b)], ["Location", Fx.dirOf(es[0].path)]] };
    }
    function bulkRename(es, pat) {
        pat = pat.trim();
        if (pat === "")
            return;
        if (pat.indexOf("#") < 0)
            pat += " #";
        const w = String(es.length).length;
        const pr = [], back = [];
        es.forEach((e, i) => {
            const num = String(i + 1).padStart(w, "0");
            const x = e.dir ? "" : Fx.ext(e.name);
            const nn = pat.replace("#", num) + (x !== "" ? "." + x : "");
            pr.push(e.path, Fx.dirOf(e.path) + "/" + nn);
            back.push(Fx.dirOf(e.path) + "/" + nn, e.path);
        });
        const e = { label: "Rename", fwd: () => exec(sh("reverse.sh", pr)), bwd: () => exec(sh("reverse.sh", back)) };
        e.fwd();
        pushUndo(e);
        const p = activePane();
        if (p)
            p.sel = [];
    }
    function menuAct(id) {
        const p = mctx.pane || activePane();
        if (!p)
            return;
        const es = p.selEntries();
        const one = es.length === 1 ? es[0] : null;
        const paths = p.sel.slice();
        if (id.indexOf("s:") === 0) {
            const k = id.substring(2);
            if (k === "desc")
                sortDesc = !sortDesc;
            else
                sortKey = k;
            return;
        }
        if (id.indexOf("v:") === 0) {
            view = id.substring(2);
            return;
        }
        if (id.indexOf("cz:") === 0) {
            const fmt = id.substring(3);
            const suggested = paths.length === 1 ? Fx.base(paths[0]).replace(/\.[^.]*$/, "") || Fx.base(paths[0]) : "Archive";
            ask("Compress as ." + fmt, suggested, "Compress", name => compress(fmt, name, paths));
            return;
        }
        switch (id) {
        case "open": for (const e of es) p.open(e); break;
        case "newtab": if (one && one.dir) newTab(one.path); else newTab(p.path); break;
        case "inother": { const o = otherPane(); if (one && o) o.go(one.path); break; }
        case "openwith": if (one) { owPath = one.path; owQuery = ""; } break;
        case "terminal": terminalAt(one && one.dir ? one.path : p.path); break;
        case "cut": setClip(true); break;
        case "copy": setClip(false); break;
        case "paste": paste(); break;
        case "pasteinto": if (one && clipPaths.length) { copyMove(cutMode ? "mv" : "cp", clipPaths, one.path); if (cutMode) clipPaths = []; } break;
        case "dup": copyMove("cp", paths, p.path); p.sel = []; break;
        case "rename":
            if (one)
                ask("Rename", one.name, "Rename", n => rename(one.path, n.trim()));
            else if (es.length > 1)
                ask("Rename " + es.length + " items (# = number)", "Item #", "Rename", n => bulkRename(es, n));
            break;
        case "copyto": case "moveto": {
            const o = otherPane();
            const mode = id === "copyto" ? "cp" : "mv";
            if (paths.length)
                ask((mode === "cp" ? "Copy" : "Move") + " " + paths.length + " item(s) to", o ? o.path : p.path, mode === "cp" ? "Copy" : "Move", d => copyMove(mode, paths, d.trim().replace(/^~/, home)));
            break;
        }
        case "copyother": { const o = otherPane(); if (o && paths.length) copyMove("cp", paths, o.path); break; }
        case "moveother": { const o = otherPane(); if (o && paths.length) copyMove("mv", paths, o.path); break; }
        case "link":
            if (one) {
                const dst = p.path + "/Link to " + one.name;
                const e = { label: "Link", fwd: () => exec(["ln", "-s", "--", one.path, dst]), bwd: () => exec(["rm", "-f", "--", dst]) };
                e.fwd();
                pushUndo(e);
            }
            break;
        case "newlink":
            ask("Link to (path)", home, "Create", t => {
                const tgt = t.trim().replace(/^~/, home);
                const dst = p.path + "/Link to " + Fx.base(tgt);
                const e = { label: "Link", fwd: () => exec(["ln", "-s", "--", tgt, dst]), bwd: () => exec(["rm", "-f", "--", dst]) };
                e.fwd();
                pushUndo(e);
            });
            break;
        case "wallpaper":
            if (one) {
                exec(["sh", "-c", "mkdir -p \"$HOME/Pictures/Wallpapers\" && cp -n -- \"$1\" \"$HOME/Pictures/Wallpapers/\"", "sh", one.path], null, true);
                toast("Added to wallpapers");
            }
            break;
        case "checksum":
            if (one)
                exec(["sha256sum", "--", one.path], t => { props = { name: one.name, rows: [["SHA-256", t.split(" ")[0]], ["Path", one.path]] }; }, true);
            break;
        case "perms":
            if (paths.length)
                ask("Permissions (e.g. 644, 755, +x)", "+x", "Apply", m => exec(["chmod", m.trim(), "--"].concat(paths)));
            break;
        case "compress": break;
        case "extract": for (const e of es) extract(e.path); break;
        case "copypath": Quickshell.execDetached(["wl-copy", (paths.length ? paths : [p.path]).join("\n")]); toast("Location copied"); break;
        case "bookmark": {
            const bp = one && one.dir ? one.path : p.path;
            if (!p.isPc && bookmarks.every(b => b.p !== bp))
                bookmarks = bookmarks.concat([{ n: Fx.base(bp) || "/", p: bp }]);
            break;
        }
        case "rmbm": bookmarks = bookmarks.filter(b => b.p !== mctx.bm); break;
        case "placetab": newTab(mctx.p || mctx.bm); break;
        case "props": if (one) showProps(one.path, one.name); else if (es.length > 1) showPropsMulti(es); break;
        case "folderprops": showProps(p.path, Fx.base(p.path) || "/"); break;
        case "trash": trashSel(paths); break;
        case "restore": restoreSel(paths); break;
        case "restoreall": restoreSel(p.raw.map(e => e.path)); break;
        case "delperm": deleteForever(paths); break;
        case "emptytrash": emptyTrash(); break;
        case "newfolder": ask("New folder", "New folder", "Create", n => create(true, n)); break;
        case "newfile": ask("New text file", "New file.txt", "Create", n => create(false, n)); break;
        case "selall": p.selectAll(); break;
        case "selnone": p.sel = []; break;
        case "invert": p.invert(); break;
        case "selmatch":
            ask("Select matching (e.g. *.png)", "*", "Select", g => {
                const re = new RegExp("^" + g.trim().replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".") + "$", "i");
                p.sel = p.entries.filter(e => re.test(e.name)).map(e => e.path);
            });
            break;
        case "hidden": showHidden = !showHidden; break;
        case "single": singleClick = !singleClick; break;
        case "info": info = !info; break;
        case "split": toggleSplit(); break;
        case "zoomin": zoom = Math.min(128, zoom + 16); break;
        case "zoomout": zoom = Math.max(48, zoom - 16); break;
        case "undo": undo(); break;
        case "redo": redo(); break;
        case "refresh": refreshAll(); break;
        case "drvopen": goActive(mctx.drive.mount); break;
        case "drvtab": newTab(mctx.drive.mount); break;
        case "drvmount": mountDrive(mctx.drive, activePane()); break;
        case "drvunmount": unmountDrive(mctx.drive); break;
        case "tabclose": closeTab(mctx.tab); break;
        case "tabdup": { const t = tabRep.itemAt(mctx.tab); newTab(t ? t.active.path : home); break; }
        case "tabothers":
            for (let j = tabs.count - 1; j >= 0; j--)
                if (j !== mctx.tab)
                    tabs.remove(j);
            cur = 0;
            ap = activePane();
            break;
        }
    }

    // ================================ UI =========================================================
    Item {
        id: content
        anchors.fill: parent

        // Navigation drawer
        Item {
            id: side
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: win.sidebarOpen ? 270 : 0
            clip: true
            Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            component SideItem: Rectangle {
                id: si
                property string icon: ""
                property string label: ""
                property bool current: false
                signal clicked
                signal held
                width: 246
                height: 48
                radius: 24
                color: current ? AppTheme.accentSoft : (sm.pressed ? AppTheme.hover : "transparent")
                Ico { x: 16; y: 12; size: 24; name: si.icon; color: si.current ? AppTheme.accent : AppTheme.dim }
                Text {
                    x: 54
                    width: parent.width - 66
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: si.label
                    elide: Text.ElideRight
                    color: si.current ? AppTheme.accent : AppTheme.text
                    font.pixelSize: 15
                    font.weight: si.current ? Font.DemiBold : Font.Normal
                }
                MouseArea { id: sm; anchors.fill: parent; onClicked: si.clicked(); onPressAndHold: si.held() }
            }

            Flickable {
                anchors.fill: parent
                anchors.topMargin: 8
                contentWidth: width
                contentHeight: sc.implicitHeight + 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: sc
                    x: 12
                    width: 246
                    spacing: 2
                    Text { text: "Files"; color: AppTheme.accent; font.pixelSize: 24; font.weight: Font.DemiBold; leftPadding: 16; topPadding: 6; bottomPadding: 12 }
                    Repeater {
                        model: win.places
                        SideItem {
                            required property var modelData
                            icon: modelData.ico
                            label: modelData.n
                            current: win.ap !== null && win.ap.path === modelData.p
                            onClicked: win.goActive(modelData.p)
                            onHeld: {
                                const g = mapToItem(null, 40, 30);
                                win.placeMenu(modelData.p, g.x, g.y);
                            }
                        }
                    }
                    Text { visible: win.bookmarks.length > 0; text: "Bookmarks"; color: AppTheme.dim; font.pixelSize: 13; font.weight: Font.DemiBold; leftPadding: 16; topPadding: 14; bottomPadding: 4 }
                    Repeater {
                        model: win.bookmarks
                        SideItem {
                            required property var modelData
                            icon: "folder"
                            label: modelData.n
                            current: win.ap !== null && win.ap.path === modelData.p
                            onClicked: win.goActive(modelData.p)
                            onHeld: {
                                win.mctx = { bm: modelData.p, pane: win.activePane() };
                                const g = mapToItem(null, 40, 30);
                                ctxMenu.popup(g.x, g.y, [{ id: "placetab", ico: "plus", label: "Open in new tab" }, { id: "rmbm", ico: "close", label: "Remove bookmark", danger: true }]);
                            }
                        }
                    }
                    Text { text: "Devices"; color: AppTheme.dim; font.pixelSize: 13; font.weight: Font.DemiBold; leftPadding: 16; topPadding: 14; bottomPadding: 4 }
                    SideItem { icon: "computer"; label: "This PC"; current: win.ap !== null && win.ap.isPc; onClicked: win.goActive("pc://") }
                    Repeater {
                        model: win.drives
                        SideItem {
                            required property var modelData
                            icon: modelData.removable ? "sd" : "drive"
                            label: modelData.title + (modelData.mount === "" ? "  \u00b7  tap to mount" : "")
                            current: win.ap !== null && modelData.mount !== "" && win.ap.path === modelData.mount
                            onClicked: modelData.mount === "" ? win.mountDrive(modelData, win.activePane()) : win.goActive(modelData.mount)
                            onHeld: {
                                const g = mapToItem(null, 40, 30);
                                win.driveMenu(modelData, g.x, g.y);
                            }
                        }
                    }
                }
            }
        }

        // Info panel (right)
        InfoPanel {
            id: infoP
            host: win
            visible: win.showInfo
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 8
            anchors.leftMargin: 0
            width: visible ? 320 : 0
        }

        // Main surface
        Rectangle {
            id: main
            anchors.left: side.right
            anchors.right: infoP.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 8
            anchors.leftMargin: win.sidebarOpen ? 0 : 8
            anchors.rightMargin: win.showInfo ? 8 : 0
            radius: 32
            color: AppTheme.low

            // toolbar
            Item {
                id: tb
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 64
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Pill { icon: "menu"; flat: true; onClicked: win.sidebarOpen = !win.sidebarOpen }
                    Pill { icon: "back"; flat: true; enabled: win.ap !== null && win.ap.hpos > 0; onClicked: win.ap.back() }
                    Pill { icon: "fwd"; flat: true; enabled: win.ap !== null && win.ap.hpos < win.ap.hist.length - 1; onClicked: win.ap.forward() }
                    Pill { icon: "up"; flat: true; enabled: win.ap !== null && !win.ap.isPc && win.ap.path !== "/"; onClicked: win.ap.up() }
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Rectangle {
                        width: filterIn.activeFocus ? 250 : (win.wide ? 190 : 120)
                        height: 44
                        radius: 22
                        color: AppTheme.card
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Ico { x: 14; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 20; color: AppTheme.dim }
                        Text { x: 40; height: parent.height; verticalAlignment: Text.AlignVCenter; visible: filterIn.text === ""; text: "Filter \u00b7 Enter searches"; color: AppTheme.dim; font.pixelSize: 14; width: parent.width - 52; elide: Text.ElideRight }
                        TextInput {
                            id: filterIn
                            x: 40
                            width: parent.width - 52
                            height: parent.height
                            verticalAlignment: TextInput.AlignVCenter
                            color: AppTheme.text
                            font.pixelSize: 15
                            clip: true
                            onTextChanged: {
                                const p = win.activePane();
                                if (p && !p.searching)
                                    p.query = text;
                            }
                            onAccepted: {
                                const p = win.activePane();
                                if (p && text.trim() !== "") {
                                    p.query = "";
                                    p.search(text);
                                }
                            }
                            Keys.onEscapePressed: {
                                const p = win.activePane();
                                text = "";
                                if (p) {
                                    p.query = "";
                                    if (p.searching) {
                                        p.searchTerm = "";
                                        p.refresh();
                                    }
                                }
                                focus = false;
                            }
                        }
                    }
                    Rectangle {
                        width: seg.width + 8
                        height: 44
                        radius: 22
                        color: AppTheme.card
                        Row {
                            id: seg
                            anchors.centerIn: parent
                            spacing: 0
                            Pill { icon: "grid"; flat: true; on: win.view === "grid"; height: 38; onClicked: win.view = "grid" }
                            Pill { icon: "list"; flat: true; on: win.view === "list"; height: 38; onClicked: win.view = "list" }
                            Pill { icon: "columns"; flat: true; on: win.view === "columns"; height: 38; onClicked: win.view = "columns" }
                        }
                    }
                    Pill { icon: "split"; visible: win.wide; on: win.ap !== null && win.activeTab() !== null && win.activeTab().split; onClicked: win.toggleSplit() }
                    Pill { icon: "info"; visible: win.wide; on: win.info; onClicked: win.info = !win.info }
                    Pill {
                        icon: "more"
                        onClicked: {
                            const g = mapToItem(null, 0, height + 6);
                            win.moreMenu(g.x - 190, g.y);
                        }
                    }
                    Pill { icon: "close"; onClicked: Qt.quit() }
                }
            }

            // tab bar
            Item {
                id: tbar
                anchors.top: tb.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: tabs.count > 1 ? 46 : 0
                visible: tabs.count > 1
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Repeater {
                        model: tabs
                        Rectangle {
                            id: tc
                            required property int index
                            required property string title
                            width: Math.min(200, tt.implicitWidth + 62)
                            height: 38
                            radius: 19
                            color: tc.index === win.cur ? AppTheme.accentSoft : AppTheme.card
                            Text { id: tt; x: 16; height: parent.height; verticalAlignment: Text.AlignVCenter; width: parent.width - 52; text: tc.title; elide: Text.ElideRight; color: tc.index === win.cur ? AppTheme.accent : AppTheme.text; font.pixelSize: 14 }
                            Ico { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; name: "close"; size: 14; color: AppTheme.dim
                                MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: win.closeTab(tc.index) } }
                            MouseArea {
                                anchors.fill: parent
                                anchors.rightMargin: 36
                                onClicked: { win.cur = tc.index; win.ap = win.activePane(); }
                                onPressAndHold: { const g = tc.mapToItem(null, 20, 40); win.tabMenu(tc.index, g.x, g.y); }
                            }
                        }
                    }
                    Pill { icon: "plus"; flat: true; height: 38; onClicked: win.newTab("") }
                }
            }

            // panes
            Item {
                id: tabHost
                anchors.top: tbar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: status.top
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                Repeater {
                    id: tabRep
                    model: tabs
                    TabView {
                        host: win
                        anchors.fill: parent
                    }
                }
            }

            // status bar
            Item {
                id: status
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 44
                Text { x: 22; height: parent.height; verticalAlignment: Text.AlignVCenter; text: win.statusText; color: AppTheme.dim; font.pixelSize: 13; visible: !win.cpBusy }
                Item {
                    visible: win.cpBusy
                    x: 22
                    width: parent.width - 44 - (win.view === "grid" && win.wide ? 180 : 0)
                    height: parent.height
                    Text { id: cpTx; height: parent.height; verticalAlignment: Text.AlignVCenter; text: win.cpTotal > 0 ? Math.round(100 * win.cpDone / win.cpTotal) + "%  \u00b7  " + Fx.human(win.cpDone) + " / " + Fx.human(win.cpTotal) : "Working\u2026"; color: AppTheme.text; font.pixelSize: 13 }
                    Rectangle {
                        x: cpTx.implicitWidth + 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(40, parent.width - x - 44)
                        height: 6
                        radius: 3
                        color: AppTheme.cardHigh
                        Rectangle { width: win.cpTotal > 0 ? parent.width * Math.min(1, win.cpDone / win.cpTotal) : 0; height: parent.height; radius: 3; color: AppTheme.accent }
                    }
                    Ico { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; name: "close"; size: 20; color: AppTheme.dim
                        MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: win.cancelCp() } }
                }
                Item {
                    visible: win.view === "grid" && win.wide
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    width: 150
                    height: 30
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: AppTheme.cardHigh }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * (win.zoom - 48) / 80; height: 6; radius: 3; color: AppTheme.accent }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; x: parent.width * (win.zoom - 48) / 80 - 9; width: 18; height: 18; radius: 9; color: AppTheme.accent }
                    MouseArea {
                        anchors.fill: parent
                        onPressed: mouse => win.zoom = Math.round(48 + 80 * Math.max(0, Math.min(1, mouse.x / width)))
                        onPositionChanged: mouse => win.zoom = Math.round(48 + 80 * Math.max(0, Math.min(1, mouse.x / width)))
                    }
                }
            }

            // selection action bar
            Rectangle {
                id: selBar
                readonly property bool shown: win.ap !== null && win.ap.sel.length > 0
                visible: shown
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: status.top
                anchors.bottomMargin: 6
                width: selRow.width + 16
                height: 56
                radius: 28
                color: AppTheme.cardHigh
                border.width: 1
                border.color: AppTheme.line
                Row {
                    id: selRow
                    anchors.centerIn: parent
                    spacing: 2
                    Pill { label: win.ap ? win.ap.sel.length + " \u2715" : ""; on: true; height: 40; onClicked: win.ap.sel = [] }
                    Pill { visible: win.ap !== null && !win.ap.inTrash; icon: "copy"; flat: true; height: 40; onClicked: win.setClip(false) }
                    Pill { visible: win.ap !== null && !win.ap.inTrash; icon: "cut"; flat: true; height: 40; onClicked: win.setClip(true) }
                    Pill { visible: win.ap !== null && win.ap.inTrash; icon: "restore"; label: "Restore"; flat: true; height: 40; onClicked: win.menuAct("restore") }
                    Pill { icon: "trash"; label: win.ap !== null && win.ap.inTrash ? "Delete" : ""; danger: true; flat: true; height: 40; onClicked: win.ap.inTrash ? win.menuAct("delperm") : win.trashSel(win.ap.sel.slice()) }
                    Pill {
                        icon: "more"
                        flat: true
                        height: 40
                        onClicked: {
                            const g = mapToItem(null, 0, 0);
                            win.mctx = { pane: win.ap, x: g.x, y: g.y };
                            win.itemMenu(win.ap, g.x - 100, g.y - 420);
                        }
                    }
                }
            }
            // paste chip when something is on the clipboard
            Pill {
                visible: win.clipPaths.length > 0 && !selBar.shown && win.ap !== null && !win.ap.isPc && !win.ap.inTrash
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: status.top
                anchors.bottomMargin: 8
                filled: true
                label: "Paste " + win.clipPaths.length
                onClicked: win.paste()
            }
            // Trash toolbar
            Row {
                visible: win.ap !== null && win.ap.inTrash
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.bottom: status.top
                anchors.bottomMargin: 8
                spacing: 8
                Pill { icon: "restore"; label: "Restore all"; onClicked: win.menuAct("restoreall") }
                Pill { icon: "trash"; label: "Empty Trash"; filled: true; danger: true; onClicked: win.emptyTrash() }
            }
            // FAB: New
            Rectangle {
                id: fab
                visible: win.ap !== null && !win.ap.isPc && !win.ap.inTrash
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.bottom: status.top
                anchors.bottomMargin: 8
                width: fl.implicitWidth + 64
                height: 56
                radius: 20
                color: AppTheme.accent
                scale: fm.pressed ? 0.94 : 1
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                Row { anchors.centerIn: parent; spacing: 8; Ico { name: "plus"; size: 20; color: AppTheme.accentInk; anchors.verticalCenter: parent.verticalCenter } Text { id: fl; text: "New"; color: AppTheme.accentInk; font.pixelSize: 16; font.weight: Font.DemiBold } }
                MouseArea {
                    id: fm
                    anchors.fill: parent
                    onClicked: {
                        const g = fab.mapToItem(null, 0, 0);
                        win.mctx = { pane: win.ap, x: g.x, y: g.y };
                        ctxMenu.popup(g.x - 200, g.y - 150, [{ id: "newfolder", ico: "newfolder", label: "New folder" }, { id: "newfile", ico: "newfile", label: "New text file" }, { id: "newlink", ico: "link", label: "New link\u2026" }, { sep: true }, { id: "paste", ico: "paste", label: "Paste", disabled: win.clipPaths.length === 0 }]);
                    }
                }
            }
        }

        // toast
        Rectangle {
            id: toastBox
            property bool show: false
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 70
            width: toastText.implicitWidth + 40
            height: 44
            radius: 22
            color: AppTheme.cardHigh
            border.width: 1
            border.color: AppTheme.line
            opacity: show ? 1 : 0
            visible: opacity > 0
            z: 150
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Text { id: toastText; anchors.centerIn: parent; color: AppTheme.text; font.pixelSize: 14 }
            Timer { id: toastTimer; interval: 2600; onTriggered: toastBox.show = false }
        }

        Rectangle {
            visible: win.dragOn
            z: 200
            readonly property point pp: parent.mapFromItem(null, win.dragX, win.dragY)
            x: pp.x + 12
            y: pp.y + 12
            width: gt.implicitWidth + 28
            height: 36
            radius: 18
            color: AppTheme.accent
            opacity: 0.92
            Text { id: gt; anchors.centerIn: parent; color: AppTheme.accentInk; font.pixelSize: 14; text: win.dragPaths.length === 1 ? Fx.base(win.dragPaths[0]) : win.dragPaths.length + " items" }
        }

        MenuPop {
            id: ctxMenu
            onPicked: id => win.menuAct(id)
        }

        // prompt / confirm dialog
        Rectangle {
            visible: win.dlg !== null
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            z: 200
            MouseArea { anchors.fill: parent; onClicked: win.dlg = null }
            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -parent.height * 0.12
                width: Math.min(480, parent.width - 40)
                height: win.dlg && win.dlg.kind === "prompt" ? 190 : 170
                radius: 32
                color: AppTheme.cardHigh
                MouseArea { anchors.fill: parent }
                Text { x: 28; y: 22; text: win.dlg ? win.dlg.title : ""; color: AppTheme.text; font.pixelSize: 20; font.weight: Font.DemiBold }
                Rectangle {
                    visible: win.dlg !== null && win.dlg.kind === "prompt"
                    x: 24
                    y: 64
                    width: parent.width - 48
                    height: 50
                    radius: 16
                    color: AppTheme.bg
                    border.width: 2
                    border.color: AppTheme.accent
                    TextInput {
                        id: dlgIn
                        anchors.fill: parent
                        anchors.margins: 14
                        color: AppTheme.text
                        font.pixelSize: 17
                        clip: true
                        selectByMouse: true
                        onAccepted: {
                            const d = win.dlg;
                            win.dlg = null;
                            if (d)
                                d.fn(text);
                        }
                        Keys.onEscapePressed: win.dlg = null
                    }
                }
                Text { visible: win.dlg !== null && win.dlg.kind === "confirm"; x: 28; y: 62; width: parent.width - 56; text: win.dlg ? win.dlg.text : ""; color: AppTheme.dim; font.pixelSize: 15; wrapMode: Text.Wrap }
                Pill { anchors.right: parent.right; anchors.rightMargin: 20; anchors.bottom: parent.bottom; anchors.bottomMargin: 16; filled: true; label: win.dlg ? win.dlg.ok : "OK"; onClicked: { const d = win.dlg; const v = dlgIn.text; win.dlg = null; if (d) d.fn(v); } }
                Pill { anchors.right: parent.right; anchors.rightMargin: 130; anchors.bottom: parent.bottom; anchors.bottomMargin: 16; flat: true; label: "Cancel"; onClicked: win.dlg = null }
            }
        }

        // properties dialog
        Rectangle {
            visible: win.props !== null
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            z: 200
            MouseArea { anchors.fill: parent; onClicked: win.props = null }
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(520, parent.width - 40)
                height: Math.min(parent.height - 60, pc.implicitHeight + 100)
                radius: 32
                color: AppTheme.cardHigh
                MouseArea { anchors.fill: parent }
                Text { x: 28; y: 22; width: parent.width - 56; text: win.props ? win.props.name : ""; color: AppTheme.text; font.pixelSize: 20; font.weight: Font.DemiBold; elide: Text.ElideMiddle }
                Flickable {
                    x: 28
                    y: 62
                    width: parent.width - 56
                    height: parent.height - 120
                    contentHeight: pc.implicitHeight
                    clip: true
                    Column {
                        id: pc
                        width: parent.width
                        spacing: 10
                        Repeater {
                            model: win.props ? win.props.rows : []
                            Column {
                                required property var modelData
                                width: pc.width
                                Text { text: modelData[0]; color: AppTheme.dim; font.pixelSize: 12 }
                                Text { width: parent.width; text: modelData[1]; color: AppTheme.text; font.pixelSize: 15; wrapMode: Text.WrapAnywhere }
                            }
                        }
                    }
                }
                Pill { anchors.right: parent.right; anchors.rightMargin: 20; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; filled: true; label: "Close"; onClicked: win.props = null }
            }
        }

        // open with
        Rectangle {
            visible: win.owPath !== ""
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            z: 200
            MouseArea { anchors.fill: parent; onClicked: win.owPath = "" }
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(460, parent.width - 40)
                height: Math.min(560, parent.height - 60)
                radius: 32
                color: AppTheme.cardHigh
                MouseArea { anchors.fill: parent }
                Text { x: 28; y: 20; text: "Open with"; color: AppTheme.text; font.pixelSize: 20; font.weight: Font.DemiBold }
                Rectangle {
                    x: 20
                    y: 60
                    width: parent.width - 40
                    height: 44
                    radius: 22
                    color: AppTheme.bg
                    TextInput {
                        id: owIn
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        verticalAlignment: TextInput.AlignVCenter
                        color: AppTheme.text
                        font.pixelSize: 16
                        onTextChanged: win.owQuery = text
                        onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                        Keys.onEscapePressed: win.owPath = ""
                    }
                }
                ListView {
                    x: 14
                    y: 114
                    width: parent.width - 28
                    height: parent.height - 130
                    clip: true
                    model: {
                        const q = win.owQuery.toLowerCase();
                        return DesktopEntries.applications.values.filter(e => !e.noDisplay && e.name.toLowerCase().indexOf(q) >= 0).sort((a, b) => a.name.localeCompare(b.name));
                    }
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 52
                        radius: 18
                        color: om.pressed ? AppTheme.accentSoft : "transparent"
                        Image { x: 12; y: 10; width: 32; height: 32; source: Quickshell.iconPath(modelData.icon, "application-x-executable"); sourceSize: Qt.size(64, 64) }
                        Text { x: 56; width: parent.width - 70; height: parent.height; verticalAlignment: Text.AlignVCenter; text: modelData.name; elide: Text.ElideRight; color: AppTheme.text; font.pixelSize: 16 }
                        MouseArea {
                            id: om
                            anchors.fill: parent
                            onClicked: {
                                Quickshell.execDetached(modelData.command.concat([win.owPath]));
                                win.owPath = "";
                            }
                        }
                    }
                }
            }
        }

        // keyboard shortcuts
        Shortcut { sequence: "Ctrl+C"; enabled: !win.typing; onActivated: win.setClip(false) }
        Shortcut { sequence: "Ctrl+X"; enabled: !win.typing; onActivated: win.setClip(true) }
        Shortcut { sequence: "Ctrl+V"; enabled: !win.typing; onActivated: win.paste() }
        Shortcut { sequence: "Ctrl+A"; enabled: !win.typing; onActivated: if (win.ap) win.ap.selectAll() }
        Shortcut { sequence: "Ctrl+Z"; enabled: !win.typing; onActivated: win.undo() }
        Shortcut { sequences: ["Ctrl+Y", "Ctrl+Shift+Z"]; enabled: !win.typing; onActivated: win.redo() }
        Shortcut { sequence: "Ctrl+H"; onActivated: win.showHidden = !win.showHidden }
        Shortcut { sequence: "Ctrl+L"; onActivated: if (win.ap) win.ap.startEdit() }
        Shortcut { sequence: "Ctrl+F"; onActivated: filterIn.forceActiveFocus() }
        Shortcut { sequence: "Ctrl+T"; enabled: !win.typing; onActivated: win.newTab("") }
        Shortcut { sequence: "Ctrl+W"; enabled: !win.typing; onActivated: win.closeTab(win.cur) }
        Shortcut { sequence: "Ctrl+I"; enabled: !win.typing; onActivated: win.info = !win.info }
        Shortcut { sequence: "F3"; enabled: !win.typing; onActivated: win.toggleSplit() }
        Shortcut { sequence: "F5"; enabled: !win.typing; onActivated: win.refreshAll() }
        Shortcut { sequence: "Ctrl+Shift+N"; enabled: !win.typing; onActivated: win.menuAct("newfolder") }
        Shortcut { sequence: "F2"; enabled: !win.typing; onActivated: win.menuAct("rename") }
        Shortcut { sequence: "Delete"; enabled: !win.typing; onActivated: if (win.ap && win.ap.sel.length) win.menuAct(win.ap.inTrash ? "delperm" : "trash") }
        Shortcut { sequence: "Shift+Delete"; enabled: !win.typing; onActivated: if (win.ap && win.ap.sel.length) win.deleteForever(win.ap.sel.slice()) }
        Shortcut { sequence: "Alt+Left"; enabled: !win.typing; onActivated: if (win.ap) win.ap.back() }
        Shortcut { sequence: "Alt+Right"; enabled: !win.typing; onActivated: if (win.ap) win.ap.forward() }
        Shortcut { sequences: ["Alt+Up", "Backspace"]; enabled: !win.typing; onActivated: if (win.ap) win.ap.up() }
        Shortcut { sequences: ["Return", "Enter"]; enabled: !win.typing; onActivated: if (win.ap) win.ap.openCursor() }
        Shortcut { sequence: "Up"; enabled: !win.typing; onActivated: if (win.ap) win.ap.move(0, -1) }
        Shortcut { sequence: "Down"; enabled: !win.typing; onActivated: if (win.ap) win.ap.move(0, 1) }
        Shortcut { sequence: "Left"; enabled: !win.typing; onActivated: if (win.ap) { if (win.view === "grid") win.ap.move(-1, 0); else win.ap.up(); } }
        Shortcut { sequence: "Right"; enabled: !win.typing; onActivated: if (win.ap) { if (win.view === "grid") win.ap.move(1, 0); else win.ap.openCursor(); } }
        Shortcut {
            sequence: "Escape"
            onActivated: {
                if (ctxMenu.visible)
                    ctxMenu.visible = false;
                else if (win.dlg !== null)
                    win.dlg = null;
                else if (win.props !== null)
                    win.props = null;
                else if (win.owPath !== "")
                    win.owPath = "";
                else if (win.ap) {
                    win.ap.sel = [];
                    win.ap.cursor = -1;
                }
            }
        }
    }
}

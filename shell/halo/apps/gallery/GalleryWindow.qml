import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Halo Gallery: iPad Photos (sidebar, Years/Months/Days/All, Albums, Favorites, Recently Deleted)
// mixed with Aves (selection mode, pinch grid, viewer with filmstrip, info sheet, slideshow, rotate).
AppWindow {
    id: root
    title: "Gallery"
    heading: viewing ? (shown[cur] ? shown[cur].name : "") : (selMode ? selCount + " selected" : pageTitle)
    canBack: viewing || selMode || (page === "library" && album !== "")
    onBackClicked: {
        if (viewing)
            viewing = false;
        else if (selMode)
            clearSel();
        else {
            album = "";
            page = "albums";
        }
    }

    readonly property string sd: Qt.resolvedUrl("scripts/").toString().replace("file://", "")
    readonly property string fsd: Qt.resolvedUrl("../files/scripts/").toString().replace("file://", "")
    readonly property string pics: AppTheme.home + "/Pictures"
    readonly property string vids: AppTheme.home + "/Videos"
    readonly property string trashDir: AppTheme.home + "/.local/share/Trash/files"
    readonly property string thumbDir: AppTheme.home + "/.cache/halo/gthumbs"

    property var media: []
    property var trashed: []
    property var pmap: ({})
    property var favs: ({})
    property var ver: ({})
    property int thumbRev: 0
    property string page: "library"   // library | favs | videos | albums | trash
    property string album: ""
    property string group: "day"      // year | month | day | all
    property int cols: 6
    property bool sideOpen: true
    property bool sortAsc: false
    property bool searching: false
    property string query: ""
    property var sel: ({})
    property bool selMode: false
    property bool selManual: false
    property bool viewing: false
    property int cur: 0
    property bool slideOn: false
    property var dlg: null
    property var mctx: ({})
    property string lastScan: ""
    property string lastTrash: ""

    readonly property int selCount: Object.keys(sel).length
    readonly property string pageTitle: page === "favs" ? "Favorites" : page === "videos" ? "Videos" : page === "albums" ? "Albums" : page === "trash" ? "Recently Deleted" : (album !== "" ? album : "Library")
    readonly property var shown: {
        let src = page === "trash" ? trashed : media;
        if (page === "favs")
            src = src.filter(e => favs[e.path] === true);
        else if (page === "videos")
            src = src.filter(e => e.video);
        else if (page === "library" && album !== "")
            src = src.filter(e => e.album === album);
        const q = query.trim().toLowerCase();
        if (q !== "")
            src = src.filter(e => e.name.toLowerCase().indexOf(q) >= 0 || e.album.toLowerCase().indexOf(q) >= 0 || dayLabel(e.mtime).toLowerCase().indexOf(q) >= 0);
        return sortAsc ? src.slice().reverse() : src;
    }
    readonly property var albumList: {
        const m = {};
        for (const e of media) {
            if (e.album === "")
                continue;
            if (!m[e.album])
                m[e.album] = { kind: "album", name: e.album, count: 0, cover: e };
            m[e.album].count++;
        }
        return Object.values(m).sort((a, b) => a.name.localeCompare(b.name));
    }
    readonly property var albumCards: {
        const fav = media.filter(e => favs[e.path] === true);
        const vid = media.filter(e => e.video);
        const out = [{ kind: "library", name: "Recents", count: media.length, cover: media.length ? media[0] : null },
                     { kind: "favs", name: "Favorites", count: fav.length, cover: fav.length ? fav[0] : null },
                     { kind: "videos", name: "Videos", count: vid.length, cover: vid.length ? vid[0] : null }];
        return out.concat(albumList).concat([{ kind: "trash", name: "Recently Deleted", count: trashed.length, cover: trashed.length ? trashed[0] : null }]);
    }

    // ---- helpers ------------------------------------------------------------------------------
    function isVideo(n) {
        return /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(n);
    }
    function dayLabel(t) {
        const d = new Date(t * 1000);
        const n = new Date();
        const a = new Date(n.getFullYear(), n.getMonth(), n.getDate()).getTime();
        const b = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
        const diff = Math.round((a - b) / 86400000);
        if (diff === 0)
            return "Today";
        if (diff === 1)
            return "Yesterday";
        return Qt.formatDate(d, "dddd, d MMMM yyyy");
    }
    function secLabel(t) {
        if (group === "day")
            return dayLabel(t);
        const d = new Date(t * 1000);
        return group === "month" ? Qt.formatDate(d, "MMMM yyyy") : (group === "year" ? Qt.formatDate(d, "yyyy") : "");
    }
    function human(b) {
        const u = ["B", "KB", "MB", "GB"];
        let i = 0;
        while (b >= 1024 && i < 3) {
            b /= 1024;
            i++;
        }
        return (i === 0 ? b : b.toFixed(1)) + " " + u[i];
    }
    function thumbOf(e) {
        return "file://" + thumbDir + "/" + Qt.md5(e.path) + ".jpg?r=" + thumbRev;
    }
    function srcOf(e) {
        if (e.video)
            return thumbOf(e);
        return "file://" + e.path + (ver[e.path] ? "?v=" + ver[e.path] : "");
    }
    function ent(p) {
        return pmap[p] || { path: p, name: p.substring(p.lastIndexOf("/") + 1), video: isVideo(p), album: "", mtime: 0, size: 0 };
    }
    function toast(m) {
        toastText.text = m;
        toastBox.show = true;
        toastTimer.restart();
    }
    function exec(cmd, cb) {
        const j = jobC.createObject(root, { command: cmd, cb: cb || null });
        j.running = true;
    }
    function ask(t, text, ok, fn) {
        dlg = { kind: "prompt", title: t, text: text, ok: ok, fn: fn };
        Qt.callLater(() => { dlgIn.text = text; dlgIn.forceActiveFocus(); dlgIn.selectAll(); });
    }
    function confirm(t, msg, ok, fn) {
        dlg = { kind: "confirm", title: t, text: msg, ok: ok, fn: fn };
    }
    function popupFrom(item, x, y, list) {
        const p = ctxMenu.mapFromItem(item, x, y);
        ctxMenu.popup(p.x, p.y, list);
    }

    // ---- scanning / persistence ---------------------------------------------------------------
    function rootOf(p) {
        return p.indexOf(vids + "/") === 0 ? vids : (p.indexOf(trashDir + "/") === 0 ? trashDir : pics);
    }
    function parseList(t, tr) {
        const out = [];
        const map = Object.assign({}, tr ? pmap : pmap);
        for (const l of t.split("\n")) {
            const a = l.indexOf("\t");
            const b = l.indexOf("\t", a + 1);
            if (a < 0 || b < 0)
                continue;
            const p = l.substring(b + 1);
            const r = rootOf(p);
            const rel = p.substring(r.length + 1);
            const slash = rel.indexOf("/");
            const name = rel.substring(rel.lastIndexOf("/") + 1);
            const alb = tr ? "" : (slash > 0 ? rel.substring(0, slash) : (r === vids ? "Videos" : ""));
            const e = { path: p, name: name, mtime: parseFloat(l.substring(0, a)), size: parseInt(l.substring(a + 1, b)), album: alb, video: isVideo(name) };
            out.push(e);
            map[p] = e;
        }
        out.sort((x, y) => y.mtime - x.mtime);
        pmap = map;
        return out;
    }
    function rescan() {
        scan.running = false;
        scan.running = true;
        tscan.running = false;
        tscan.running = true;
    }
    function save() {
        saveTimer.restart();
    }
    Timer {
        id: saveTimer
        interval: 500
        onTriggered: cfg.setText(JSON.stringify({ favs: Object.keys(root.favs), cols: root.cols, group: root.group, sideOpen: root.sideOpen, sortAsc: root.sortAsc }))
    }
    FileView {
        id: cfg
        path: AppTheme.home + "/.config/halo/gallery.json"
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                const j = JSON.parse(text());
                const f = {};
                for (const p of (j.favs || []))
                    f[p] = true;
                root.favs = f;
                if (j.cols)
                    root.cols = Math.max(2, Math.min(12, j.cols));
                if (j.group)
                    root.group = j.group;
                if (j.sideOpen !== undefined)
                    root.sideOpen = j.sideOpen;
                root.sortAsc = !!j.sortAsc;
            } catch (e) {}
        }
    }
    Process {
        id: scan
        command: ["bash", root.sd + "scan.sh", root.pics, root.vids]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text === root.lastScan)
                    return;
                root.lastScan = text;
                root.media = root.parseList(text, false);
                vth.running = false;
                vth.running = true;
            }
        }
    }
    Process {
        id: tscan
        command: ["bash", root.sd + "scan.sh", root.trashDir]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text === root.lastTrash)
                    return;
                root.lastTrash = text;
                root.trashed = root.parseList(text, true);
            }
        }
    }
    Process {
        id: vth
        command: ["bash", root.sd + "vthumbs.sh"]
        onExited: root.thumbRev++
    }
    Timer {
        interval: 15000
        running: !root.viewing
        repeat: true
        onTriggered: root.rescan()
    }
    Component {
        id: jobC
        Process {
            id: jp
            property var cb: null
            stdout: StdioCollector {
                onStreamFinished: {
                    if (jp.cb)
                        jp.cb(text);
                    jp.destroy(1500);
                }
            }
        }
    }
    Component.onCompleted: rescan()

    // ---- selection ----------------------------------------------------------------------------
    function clearSel() {
        sel = ({});
        selMode = false;
        selManual = false;
    }
    function toggleSel(p) {
        const n = Object.assign({}, sel);
        if (n[p])
            delete n[p];
        else
            n[p] = true;
        sel = n;
        if (Object.keys(n).length === 0 && !selManual)
            selMode = false;
    }
    function selectMany(paths) {
        const n = Object.assign({}, sel);
        const all = paths.every(p => n[p]);
        for (const p of paths)
            if (all)
                delete n[p];
            else
                n[p] = true;
        sel = n;
        selMode = true;
    }
    function selectAll() {
        const n = {};
        for (const e of shown)
            n[e.path] = true;
        sel = n;
        selMode = true;
    }
    function selPaths() {
        return Object.keys(sel);
    }
    function tileTap(i) {
        if (selMode)
            toggleSel(shown[i].path);
        else
            openAt(i);
    }
    function tileHold(i) {
        selMode = true;
        const p = shown[i].path;
        if (!sel[p])
            toggleSel(p);
    }
    function openAt(i) {
        cur = i;
        viewing = true;
        viewer.openAt(i);
    }
    function setCols(n) {
        cols = Math.max(2, Math.min(12, n));
        save();
    }
    function setGroup(g) {
        group = g;
        save();
    }
    function goPage(p) {
        page = p;
        album = "";
        query = "";
        clearSel();
        viewing = false;
    }
    function openCard(c) {
        if (c.kind === "album") {
            page = "library";
            album = c.name;
        } else {
            page = c.kind;
            album = "";
        }
        clearSel();
    }

    // ---- operations ---------------------------------------------------------------------------
    function allFav(paths) {
        return paths.length > 0 && paths.every(p => favs[p] === true);
    }
    function toggleFav(paths) {
        const n = Object.assign({}, favs);
        const all = allFav(paths);
        for (const p of paths)
            if (all)
                delete n[p];
            else
                n[p] = true;
        favs = n;
        save();
    }
    function trashPaths(paths) {
        if (!paths.length)
            return;
        exec(["bash", fsd + "trash.sh"].concat(paths), () => {
            rescan();
            clearSel();
            toast(paths.length === 1 ? "Moved to Recently Deleted" : paths.length + " items moved to Recently Deleted");
        });
    }
    function baseNames(paths) {
        return paths.map(p => p.substring(p.lastIndexOf("/") + 1));
    }
    function restorePaths(paths) {
        if (!paths.length)
            return;
        exec(["bash", fsd + "restore.sh"].concat(baseNames(paths)), () => {
            rescan();
            clearSel();
            toast("Restored");
        });
    }
    function deleteForever(paths) {
        if (!paths.length)
            return;
        confirm("Delete permanently?", paths.length + " item(s) will be gone for good.", "Delete", () => {
            exec(["sh", "-c", "for f; do rm -rf -- \"$HOME/.local/share/Trash/files/$f\" \"$HOME/.local/share/Trash/info/$f.trashinfo\"; done", "sh"].concat(baseNames(paths)), () => {
                rescan();
                clearSel();
            });
        });
    }
    function emptyTrash() {
        confirm("Empty Recently Deleted?", "All items will be deleted permanently.", "Empty", () => exec(["bash", fsd + "emptytrash.sh"], () => {
            rescan();
            clearSel();
        }));
    }
    function moveTo(paths, alb) {
        const d = pics + "/" + alb;
        exec(["sh", "-c", "mkdir -p -- \"$1\"", "sh", d], () => exec(["bash", fsd + "cpmv.sh", "mv", d].concat(paths), () => {
            lastScan = "";
            rescan();
            clearSel();
            toast("Moved to " + alb);
        }));
    }
    function rotate(paths, deg) {
        const imgs = paths.filter(p => !ent(p).video && !/\.gif$/i.test(p));
        if (!imgs.length) {
            toast("Nothing to rotate");
            return;
        }
        exec(["bash", sd + "rotate.sh", "" + deg].concat(imgs), () => {
            const n = Object.assign({}, ver);
            for (const p of imgs)
                n[p] = Date.now();
            ver = n;
            toast("Rotated");
        });
    }
    function copyImage(p) {
        exec(["bash", sd + "copyimg.sh", p], () => toast("Image copied"));
    }
    function copyPaths(paths) {
        Quickshell.execDetached(["wl-copy", paths.join("\n")]);
        toast("Path copied");
    }
    function addWallpaper(p) {
        exec(["sh", "-c", "mkdir -p \"$HOME/Pictures/Wallpapers\" && cp -n -- \"$1\" \"$HOME/Pictures/Wallpapers/\"", "sh", p], () => toast("Added to wallpapers"));
    }
    function openExternal(p) {
        Quickshell.execDetached(["xdg-open", p]);
    }
    function startSlideshow() {
        if (shown.length === 0)
            return;
        slideOn = true;
        openAt(0);
    }

    // ---- menus --------------------------------------------------------------------------------
    function mi(id, label, ico, o) {
        return Object.assign({ id: id, label: label, ico: ico }, o || {});
    }
    function albumSub() {
        const s = albumList.map(a => mi("mv:" + a.name, a.name, "album"));
        return s.concat([{ sep: true }, mi("newalbum", "New album\u2026", "plus")]);
    }
    function itemMenu(item, x, y, paths) {
        mctx = { paths: paths };
        const one = paths.length === 1 ? ent(paths[0]) : null;
        const hasImg = paths.some(p => !ent(p).video);
        let m;
        if (page === "trash") {
            m = [mi("restore", "Restore", "restore"), mi("delperm", "Delete permanently", "trash", { danger: true })];
        } else {
            m = [];
            if (one)
                m.push(mi("open", "Open", "open"));
            m.push(mi("fav", allFav(paths) ? "Remove from Favorites" : "Add to Favorites", "heart"));
            if (one && !one.video)
                m.push(mi("copyimg", "Copy image", "copy"));
            m.push(mi("copypath", "Copy path", "link"), { sep: true });
            if (hasImg)
                m.push(mi("rotl", "Rotate left", "rotl"), mi("rotr", "Rotate right", "rotr"));
            m.push({ label: "Move to album", ico: "album", sub: albumSub() });
            if (one && !one.video)
                m.push(mi("wallpaper", "Add to wallpapers", "image"));
            if (one)
                m.push(mi("openwith", "Open with default app", "open"), mi("info", "Info", "info"));
            m.push({ sep: true }, mi("select", "Select", "select"), mi("trash", "Move to Recently Deleted", "trash", { danger: true }));
        }
        popupFrom(item, x, y, m);
    }
    function moreMenu(item, x, y) {
        mctx = { paths: selPaths() };
        const m = [mi("zin", "Larger photos", "zoomin"), mi("zout", "Smaller photos", "zoomout"), { sep: true },
                   mi("sort", sortAsc ? "Sort newest first" : "Sort oldest first", "sort"),
                   mi("selmode", "Select", "select"), mi("selall", "Select all", "select"),
                   mi("slide", "Slideshow", "play"), mi("refresh", "Refresh", "refresh")];
        if (page === "trash")
            m.push({ sep: true }, mi("restoreall", "Restore all", "restore"), mi("emptytrash", "Empty Recently Deleted", "trash", { danger: true }));
        popupFrom(item, x, y, m);
    }
    function menuAct(id) {
        const paths = mctx.paths || [];
        if (id.indexOf("mv:") === 0) {
            moveTo(paths, id.substring(3));
            return;
        }
        switch (id) {
        case "open": openAt(shown.findIndex(e => e.path === paths[0])); break;
        case "fav": toggleFav(paths); break;
        case "copyimg": copyImage(paths[0]); break;
        case "copypath": copyPaths(paths); break;
        case "rotl": rotate(paths, -90); break;
        case "rotr": rotate(paths, 90); break;
        case "newalbum": ask("New album", "", "Create", n => { if (n.trim() !== "") moveTo(paths, n.trim().split("/").join("-")); }); break;
        case "wallpaper": addWallpaper(paths[0]); break;
        case "openwith": openExternal(paths[0]); break;
        case "info": { const i = shown.findIndex(e => e.path === paths[0]); if (i >= 0) { openAt(i); viewer.showInfo(); } break; }
        case "select": selManual = true; selMode = true; if (paths.length === 1) toggleSel(paths[0]); break;
        case "trash": trashPaths(paths); break;
        case "restore": restorePaths(paths); break;
        case "delperm": deleteForever(paths); break;
        case "zin": setCols(cols - 1); break;
        case "zout": setCols(cols + 1); break;
        case "sort": sortAsc = !sortAsc; save(); break;
        case "selmode": selManual = true; selMode = true; break;
        case "selall": selectAll(); break;
        case "slide": startSlideshow(); break;
        case "refresh": lastScan = ""; lastTrash = ""; rescan(); break;
        case "restoreall": restorePaths(trashed.map(e => e.path)); break;
        case "emptytrash": emptyTrash(); break;
        }
    }

    // ---- title-bar actions --------------------------------------------------------------------
    readonly property bool grouped: page === "library" || page === "favs" || page === "videos"
    actions: [
        Pill { visible: !root.viewing && !root.selMode; icon: "sidebar"; flat: true; on: root.sideOpen; onClicked: { root.sideOpen = !root.sideOpen; root.save(); } },
        Pill { visible: !root.viewing && !root.selMode && root.grouped && root.width > 900; label: "Years"; on: root.group === "year"; onClicked: root.setGroup("year") },
        Pill { visible: !root.viewing && !root.selMode && root.grouped && root.width > 900; label: "Months"; on: root.group === "month"; onClicked: root.setGroup("month") },
        Pill { visible: !root.viewing && !root.selMode && root.grouped && root.width > 900; label: "Days"; on: root.group === "day"; onClicked: root.setGroup("day") },
        Pill { visible: !root.viewing && !root.selMode && root.grouped && root.width > 900; label: "All"; on: root.group === "all"; onClicked: root.setGroup("all") },
        Pill { visible: !root.viewing && !root.selMode && root.page !== "albums"; icon: "search"; flat: true; on: root.searching; onClicked: { root.searching = !root.searching; if (!root.searching) root.query = ""; else Qt.callLater(() => searchIn.forceActiveFocus()); } },
        Pill { visible: !root.viewing && !root.selMode && root.page !== "albums"; label: "Select"; onClicked: { root.selManual = true; root.selMode = true; } },
        Pill { id: moreBtn; visible: !root.viewing && !root.selMode && root.page !== "albums"; icon: "more"; flat: true; onClicked: root.moreMenu(moreBtn, 0, moreBtn.height) },
        // selection mode
        Pill { visible: root.selMode && !root.viewing; label: "All"; onClicked: root.selectAll() },
        Pill { visible: root.selMode && !root.viewing && root.page !== "trash"; icon: "heart"; enabled: root.selCount > 0; onClicked: root.toggleFav(root.selPaths()) },
        Pill { id: selMore; visible: root.selMode && !root.viewing && root.page !== "trash"; icon: "more"; enabled: root.selCount > 0; onClicked: root.itemMenu(selMore, 0, selMore.height, root.selPaths()) },
        Pill { visible: root.selMode && !root.viewing && root.page !== "trash"; icon: "trash"; danger: true; enabled: root.selCount > 0; onClicked: root.trashPaths(root.selPaths()) },
        Pill { visible: root.selMode && !root.viewing && root.page === "trash"; icon: "restore"; label: "Restore"; enabled: root.selCount > 0; onClicked: root.restorePaths(root.selPaths()) },
        Pill { visible: root.selMode && !root.viewing && root.page === "trash"; icon: "trash"; danger: true; label: "Delete"; enabled: root.selCount > 0; onClicked: root.deleteForever(root.selPaths()) },
        Pill { visible: root.selMode && !root.viewing; icon: "close"; flat: true; onClicked: root.clearSel() }
    ]

    // ---- UI -----------------------------------------------------------------------------------
    Item {
        anchors.fill: parent

        // iPad-style sidebar
        Rectangle {
            id: side
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.sideOpen && !root.viewing ? 250 : 0
            visible: width > 0
            color: AppTheme.low
            clip: true
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Flickable {
                anchors.fill: parent
                anchors.margins: 10
                contentHeight: sideCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: sideCol
                    width: parent.width
                    spacing: 2
                    Text { text: "Photos"; color: AppTheme.dim; font.pixelSize: 13; font.weight: Font.DemiBold; leftPadding: 12; topPadding: 6; bottomPadding: 6 }
                    Repeater {
                        model: [{ id: "library", n: "Library", i: "image" }, { id: "favs", n: "Favorites", i: "heart" }, { id: "videos", n: "Videos", i: "video" }, { id: "albums", n: "Albums", i: "album" }, { id: "trash", n: "Recently Deleted", i: "trash" }]
                        Rectangle {
                            id: si
                            required property var modelData
                            readonly property bool here: modelData.id === "library" ? (root.page === "library" && root.album === "") : root.page === modelData.id
                            width: sideCol.width
                            height: 46
                            radius: 23
                            color: here ? AppTheme.accentSoft : (sm.containsMouse ? AppTheme.hover : "transparent")
                            Ico { x: 14; anchors.verticalCenter: parent.verticalCenter; name: si.modelData.i; size: 22; color: si.here ? AppTheme.accent : AppTheme.dim }
                            Text { x: 48; width: parent.width - 60; anchors.verticalCenter: parent.verticalCenter; text: si.modelData.n; elide: Text.ElideRight; color: si.here ? AppTheme.accent : AppTheme.text; font.pixelSize: 15; font.weight: si.here ? Font.DemiBold : Font.Normal }
                            MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; onClicked: root.goPage(si.modelData.id) }
                        }
                    }
                    Text { visible: root.albumList.length > 0; text: "My albums"; color: AppTheme.dim; font.pixelSize: 13; font.weight: Font.DemiBold; leftPadding: 12; topPadding: 16; bottomPadding: 6 }
                    Repeater {
                        model: root.albumList
                        Rectangle {
                            id: ai
                            required property var modelData
                            readonly property bool here: root.page === "library" && root.album === modelData.name
                            width: sideCol.width
                            height: 46
                            radius: 23
                            color: here ? AppTheme.accentSoft : (am.containsMouse ? AppTheme.hover : "transparent")
                            Ico { x: 14; anchors.verticalCenter: parent.verticalCenter; name: "folder"; size: 22; color: ai.here ? AppTheme.accent : AppTheme.dim }
                            Text { x: 48; width: parent.width - 100; anchors.verticalCenter: parent.verticalCenter; text: ai.modelData.name; elide: Text.ElideRight; color: ai.here ? AppTheme.accent : AppTheme.text; font.pixelSize: 15 }
                            Text { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: ai.modelData.count; color: AppTheme.dim; font.pixelSize: 13 }
                            MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: root.openCard(ai.modelData) }
                        }
                    }
                }
            }
        }

        // main column
        Item {
            id: main
            anchors.left: side.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Rectangle {
                id: sbar
                visible: root.searching
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                anchors.topMargin: 4
                height: root.searching ? 46 : 0
                radius: 23
                color: AppTheme.card
                Ico { x: 14; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 20; color: AppTheme.dim }
                TextInput {
                    id: searchIn
                    x: 46
                    width: parent.width - 90
                    anchors.verticalCenter: parent.verticalCenter
                    color: AppTheme.text
                    font.pixelSize: 16
                    clip: true
                    onTextChanged: root.query = text
                    Text { visible: searchIn.text === ""; text: "Search name, album or date"; color: AppTheme.dim; font.pixelSize: 16 }
                }
            }

            GGrid {
                id: grid
                host: root
                visible: root.page !== "albums"
                anchors.top: sbar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
            }
            GAlbums {
                host: root
                visible: root.page === "albums"
                anchors.fill: parent
            }
            Text {
                visible: root.page !== "albums" && root.shown.length === 0
                anchors.centerIn: parent
                text: root.page === "trash" ? "Nothing deleted" : (root.query !== "" ? "No results" : (root.page === "favs" ? "No favorites yet" : "No photos in ~/Pictures or ~/Videos"))
                color: AppTheme.dim
                font.pixelSize: 18
            }
        }

        GViewer {
            id: viewer
            host: root
            visible: root.viewing
            anchors.fill: parent
            z: 50
        }

        Rectangle {
            id: toastBox
            property bool show: false
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 110
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
            Timer { id: toastTimer; interval: 2400; onTriggered: toastBox.show = false }
        }

        MenuPop {
            id: ctxMenu
            onPicked: id => root.menuAct(id)
        }

        // prompt / confirm dialog
        Rectangle {
            visible: root.dlg !== null
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            z: 200
            MouseArea { anchors.fill: parent; onClicked: root.dlg = null }
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(460, parent.width - 40)
                height: root.dlg && root.dlg.kind === "prompt" ? 190 : 170
                radius: 32
                color: AppTheme.cardHigh
                MouseArea { anchors.fill: parent }
                Text { x: 28; y: 22; text: root.dlg ? root.dlg.title : ""; color: AppTheme.text; font.pixelSize: 20; font.weight: Font.DemiBold }
                Text { visible: root.dlg !== null && root.dlg.kind === "confirm"; x: 28; y: 64; width: parent.width - 56; text: root.dlg ? root.dlg.text : ""; color: AppTheme.dim; font.pixelSize: 15; wrapMode: Text.WordWrap }
                Rectangle {
                    visible: root.dlg !== null && root.dlg.kind === "prompt"
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
                        verticalAlignment: TextInput.AlignVCenter
                        color: AppTheme.text
                        font.pixelSize: 16
                        clip: true
                        onAccepted: dlgOk.clicked()
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 20
                    spacing: 8
                    Pill { label: "Cancel"; flat: true; onClicked: root.dlg = null }
                    Pill {
                        id: dlgOk
                        label: root.dlg ? root.dlg.ok : ""
                        filled: true
                        onClicked: {
                            const d = root.dlg;
                            root.dlg = null;
                            if (d && d.fn)
                                d.fn(d.kind === "prompt" ? dlgIn.text : "");
                        }
                    }
                }
            }
        }

        Shortcut { sequence: "Escape"; enabled: !root.viewing && root.dlg === null; onActivated: { if (root.selMode) root.clearSel(); else if (root.searching) { root.searching = false; root.query = ""; } } }
        Shortcut { sequence: "Ctrl+A"; enabled: !root.viewing && root.dlg === null && !searchIn.activeFocus; onActivated: root.selectAll() }
        Shortcut { sequence: "Delete"; enabled: !root.viewing && root.dlg === null && root.selCount > 0 && !searchIn.activeFocus; onActivated: root.page === "trash" ? root.deleteForever(root.selPaths()) : root.trashPaths(root.selPaths()) }
    }
}

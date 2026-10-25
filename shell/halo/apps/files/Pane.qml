import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// One folder view: breadcrumb bar + (grid | details list | Miller columns) + This PC dashboard.
Item {
    id: pane
    required property var win
    property string path: ""
    property bool isActive: false
    property var hist: []
    property int hpos: -1
    property var raw: []
    property var parentRaw: []
    property var sel: []
    property string query: ""
    property string searchTerm: ""
    property int cursor: -1
    property int anchorIdx: -1
    property bool editing: false
    property string dropPath: ""
    property var thumbOk: ({})
    function folderAt(gx, gy) {
        const q = view.mapFromItem(null, gx, gy);
        if (q.x < 0 || q.y < 0 || q.x > view.width || q.y > view.height)
            return "";
        const i = view.indexAt(q.x + view.contentX, q.y + view.contentY);
        const e = i >= 0 ? entries[i] : null;
        return e && e.dir ? e.path : "";
    }
    // video / pdf thumbnails (thumbs.sh, cache shared with Gallery)
    function thumbUrl(path) { return "file://" + win.home + "/.cache/halo/gthumbs/" + Qt.md5(path) + ".jpg"; }
    function wantThumbs() {
        if (win.view !== "grid" || isPc)
            return;
        const l = entries.filter(e => !e.dir && (Fx.kind(e) === "video" || Fx.kind(e) === "pdf") && !thumbOk[e.path]).slice(0, 40).map(e => e.path);
        if (l.length > 0 && !thumbP.running) {
            thumbP.list = l;
            thumbP.command = win.sh("thumbs.sh", l);
            thumbP.running = true;
        }
    }
    onEntriesChanged: thumbT.restart()
    Timer { id: thumbT; interval: 400; onTriggered: pane.wantThumbs() }
    Process {
        id: thumbP
        property var list: []
        onExited: {
            const m = Object.assign({}, pane.thumbOk);
            for (const x of list)
                m[x] = true;
            pane.thumbOk = m;
        }
    }

    readonly property bool isPc: path === "pc://"
    readonly property bool inTrash: path === win.trashFiles || path.indexOf(win.trashFiles + "/") === 0
    readonly property bool searching: searchTerm !== ""
    readonly property string title: isPc ? "This PC" : (path === win.trashFiles ? "Trash" : (path === win.home ? "Home" : Fx.base(path)))
    readonly property var entries: build(raw, query, win.showHidden, win.sortKey, win.sortDesc)
    readonly property var parentEntries: build(parentRaw, "", win.showHidden, "name", false)
    readonly property var crumbs: makeCrumbs(path, searchTerm)
    readonly property int cols: view.cols
    readonly property string fmt: "%y\t%s\t%T@\t%P\n"
    readonly property bool showCols: win.view === "list" && width > 620 && !isPc

    // ---- model -------------------------------------------------------------------------------
    function build(r, q, hid, key, desc) {
        const ql = q.toLowerCase();
        const out = r.filter(e => (hid || e.name.charAt(0) !== ".") && (ql === "" || e.name.toLowerCase().indexOf(ql) >= 0));
        const m = desc ? -1 : 1;
        out.sort((a, b) => {
            if (a.dir !== b.dir)
                return a.dir ? -1 : 1;
            let c = 0;
            if (key === "size")
                c = a.size - b.size;
            else if (key === "date")
                c = a.mtime - b.mtime;
            else if (key === "type")
                c = Fx.ext(a.name).localeCompare(Fx.ext(b.name));
            if (c === 0)
                return a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: "base" }) * m;
            return c * m;
        });
        return out;
    }
    function parse(t, basePath) {
        const out = [];
        for (const l of t.split("\n")) {
            const f = l.split("\t");
            if (f.length < 4)
                continue;
            const rel = f.slice(3).join("\t");
            out.push({ name: Fx.base(rel), rel: rel, path: (basePath === "/" ? "" : basePath) + "/" + rel, dir: f[0] === "d", size: parseInt(f[1]), mtime: parseFloat(f[2]) });
        }
        return out;
    }
    function makeCrumbs(p, term) {
        const out = [];
        if (p === "pc://") {
            out.push({ n: "This PC", p: "pc://" });
        } else {
            const roots = [[win.trashFiles, "Trash"], [win.home, "Home"], ["", "/"]];
            for (const r of roots) {
                if (r[0] === "" || p === r[0] || p.indexOf(r[0] + "/") === 0) {
                    out.push({ n: r[1], p: r[0] === "" ? "/" : r[0] });
                    let acc = r[0];
                    for (const s of p.substring(r[0].length).split("/")) {
                        if (s === "")
                            continue;
                        acc += "/" + s;
                        out.push({ n: s, p: acc });
                    }
                    break;
                }
            }
        }
        if (term !== "")
            out.push({ n: "Search: " + term, p: "" });
        return out;
    }

    function refresh() {
        if (isPc) {
            raw = [];
            parentRaw = [];
            win.refreshDrives();
            return;
        }
        lister.running = false;
        lister.command = searching ? ["find", "-L", path, "-maxdepth", "6", "-mindepth", "1", "-iname", "*" + searchTerm + "*", "-printf", fmt] : ["find", "-L", path, "-maxdepth", "1", "-mindepth", "1", "-printf", fmt];
        lister.running = true;
        if (win.view === "columns" && path !== "/") {
            plister.running = false;
            plister.command = ["find", "-L", Fx.dirOf(path), "-maxdepth", "1", "-mindepth", "1", "-printf", fmt];
            plister.running = true;
        }
    }
    function go(p, keep) {
        if (p.charAt(0) === "~")
            p = win.home + p.substring(1);
        if (p.length > 1 && p !== "pc://")
            p = p.replace(/\/+$/, "");
        if (p === "")
            p = "/";
        if (!keep) {
            hist = hist.slice(0, hpos + 1).concat([p]);
            hpos = hist.length - 1;
        }
        path = p;
        searchTerm = "";
        query = "";
        sel = [];
        cursor = -1;
        anchorIdx = -1;
        editing = false;
        if (isActive)
            win.filterClear();
        refresh();
    }
    function back() {
        if (hpos > 0) {
            hpos--;
            go(hist[hpos], true);
        }
    }
    function forward() {
        if (hpos < hist.length - 1) {
            hpos++;
            go(hist[hpos], true);
        }
    }
    function up() {
        if (!isPc && path !== "/")
            go(Fx.dirOf(path));
    }
    function search(term) {
        searchTerm = term.trim();
        query = "";
        sel = [];
        refresh();
    }
    function startEdit() {
        if (isPc)
            return;
        editing = true;
        pathIn.text = path;
        pathIn.forceActiveFocus();
        pathIn.selectAll();
    }

    // ---- selection ---------------------------------------------------------------------------
    function isSel(p) {
        return sel.indexOf(p) >= 0;
    }
    function toggle(p) {
        const s = sel.slice();
        const i = s.indexOf(p);
        if (i >= 0)
            s.splice(i, 1);
        else
            s.push(p);
        sel = s;
    }
    function selectAll() {
        sel = entries.map(e => e.path);
    }
    function invert() {
        sel = entries.filter(e => !isSel(e.path)).map(e => e.path);
    }
    function selEntries() {
        return entries.filter(e => isSel(e.path));
    }
    function open(e) {
        if (e.dir)
            go(e.path);
        else
            win.openFile(e.path);
    }
    function tap(i, mods) {
        const e = entries[i];
        if (!e)
            return;
        cursor = i;
        win.focusPane(pane);
        if (mods & Qt.ControlModifier) {
            toggle(e.path);
            anchorIdx = i;
        } else if ((mods & Qt.ShiftModifier) && anchorIdx >= 0) {
            sel = entries.slice(Math.min(anchorIdx, i), Math.max(anchorIdx, i) + 1).map(x => x.path);
        } else if (sel.length > 0) {
            toggle(e.path);
            anchorIdx = i;
        } else if (win.singleClick) {
            open(e);
        } else {
            sel = [e.path];
            anchorIdx = i;
        }
    }
    function move(dx, dy) {
        if (entries.length === 0)
            return;
        let i = cursor < 0 ? 0 : cursor + dx + dy * (win.view === "grid" ? cols : 1);
        i = Math.max(0, Math.min(entries.length - 1, i));
        cursor = i;
        sel = [entries[i].path];
        anchorIdx = i;
        view.positionViewAtIndex(i, GridView.Contain);
    }
    function openCursor() {
        const e = cursor >= 0 ? entries[cursor] : (sel.length === 1 ? selEntries()[0] : null);
        if (e)
            open(e);
    }

    Process {
        id: lister
        stdout: StdioCollector { onStreamFinished: pane.raw = pane.parse(text, pane.path) }
    }
    Process {
        id: plister
        stdout: StdioCollector { onStreamFinished: pane.parentRaw = pane.parse(text, Fx.dirOf(pane.path)) }
    }
    Connections {
        target: win
        function onViewChanged() { pane.refresh(); }
    }
    onEditingChanged: win.pathEditing = editing

    // ---- breadcrumb bar ----------------------------------------------------------------------
    Rectangle {
        id: bar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 6
        height: 48
        radius: 24
        color: AppTheme.card
        border.width: pane.isActive && win.split ? 2 : 0
        border.color: AppTheme.accent

        Flickable {
            id: cf
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            visible: !pane.editing
            clip: true
            contentWidth: crumbRow.width
            contentHeight: height
            boundsBehavior: Flickable.StopAtBounds
            onContentWidthChanged: contentX = Math.max(0, contentWidth - width)

            Row {
                id: crumbRow
                height: cf.height
                Repeater {
                    model: pane.crumbs
                    Row {
                        id: cr
                        required property var modelData
                        required property int index
                        height: crumbRow.height
                        Item {
                            visible: cr.index > 0
                            width: 18
                            height: parent.height
                            Ico { anchors.centerIn: parent; name: "fwd"; size: 14; color: AppTheme.dim }
                        }
                        Rectangle {
                            y: (parent.height - 34) / 2
                            width: ct.implicitWidth + 24
                            height: 34
                            radius: 17
                            color: cr.index === pane.crumbs.length - 1 ? AppTheme.accentSoft : (cm.pressed ? AppTheme.cardHigh : "transparent")
                            Text {
                                id: ct
                                anchors.centerIn: parent
                                text: cr.modelData.n
                                color: cr.index === pane.crumbs.length - 1 ? AppTheme.accent : AppTheme.text
                                font.pixelSize: 15
                                font.weight: cr.index === pane.crumbs.length - 1 ? Font.DemiBold : Font.Normal
                            }
                            MouseArea {
                                id: cm
                                anchors.fill: parent
                                onClicked: {
                                    pane.win.focusPane(pane);
                                    if (cr.modelData.p !== "")
                                        pane.go(cr.modelData.p);
                                }
                                onPressAndHold: pane.startEdit()
                            }
                        }
                    }
                }
            }
        }
        TextInput {
            id: pathIn
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 16
            verticalAlignment: TextInput.AlignVCenter
            visible: pane.editing
            color: AppTheme.text
            font.pixelSize: 16
            clip: true
            selectByMouse: true
            onAccepted: pane.go(text)
            Keys.onEscapePressed: pane.editing = false
            onActiveFocusChanged: if (!activeFocus) pane.editing = false
        }
    }

    // ---- columns header (details view) -------------------------------------------------------
    Item {
        id: head
        anchors.top: bar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: pane.showCols ? 34 : 0
        visible: pane.showCols
        Repeater {
            model: [{ k: "name", t: "Name", x: 52 }, { k: "size", t: "Size", x: -380 }, { k: "date", t: "Modified", x: -290 }, { k: "type", t: "Type", x: -130 }]
            Text {
                required property var modelData
                x: modelData.x >= 0 ? modelData.x : head.width + modelData.x
                height: head.height
                verticalAlignment: Text.AlignVCenter
                text: modelData.t + (win.sortKey === modelData.k ? (win.sortDesc ? "  \u25be" : "  \u25b4") : "")
                color: win.sortKey === modelData.k ? AppTheme.accent : AppTheme.dim
                font.pixelSize: 13
                font.weight: Font.DemiBold
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: {
                        if (win.sortKey === parent.modelData.k)
                            win.sortDesc = !win.sortDesc;
                        else {
                            win.sortKey = parent.modelData.k;
                            win.sortDesc = false;
                        }
                    }
                }
            }
        }
    }

    // ---- parent column (Miller / Yazi style) -------------------------------------------------
    Rectangle {
        id: pcol
        visible: win.view === "columns" && !pane.isPc && pane.path !== "/"
        anchors.top: head.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.topMargin: 4
        width: visible ? Math.min(240, pane.width * 0.28) : 0
        radius: 22
        color: AppTheme.low
        ListView {
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            model: pane.parentEntries
            boundsBehavior: Flickable.StopAtBounds
            delegate: Rectangle {
                id: pr
                required property var modelData
                readonly property bool here: modelData.path === pane.path
                width: ListView.view.width
                height: 38
                radius: 12
                color: here ? AppTheme.accent : (pm.pressed ? AppTheme.hover : "transparent")
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    text: pr.modelData.name + (pr.modelData.dir ? "/" : "")
                    elide: Text.ElideRight
                    color: pr.here ? AppTheme.accentInk : (pr.modelData.dir ? AppTheme.text : AppTheme.dim)
                    font.pixelSize: 14
                }
                MouseArea {
                    id: pm
                    anchors.fill: parent
                    onClicked: if (pr.modelData.dir) pane.go(pr.modelData.path)
                }
            }
        }
    }

    // ---- main file view ----------------------------------------------------------------------
    GridView {
        id: view
        visible: !pane.isPc
        anchors.top: head.bottom
        anchors.bottom: parent.bottom
        anchors.left: pcol.right
        anchors.right: parent.right
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: 4
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        readonly property bool isGrid: win.view === "grid"
        readonly property real tileW: win.zoom * 1.7
        readonly property int cols: isGrid ? Math.max(1, Math.floor(width / tileW)) : 1
        cellWidth: isGrid ? Math.floor(width / cols) : width
        cellHeight: isGrid ? win.zoom + 78 : (win.view === "list" ? 56 : 40)
        model: pane.entries

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool picked: pane.isSel(modelData.path)
            readonly property bool isCur: pane.isActive && pane.cursor === index
            readonly property string k: Fx.kind(modelData)
            readonly property string iconSrc: Quickshell.iconPath(Fx.icon(k), "text-x-generic")
            property bool held: false
            readonly property bool dropT: cell.modelData.dir && pane.dropPath === cell.modelData.path
            width: view.cellWidth
            height: view.cellHeight

            Loader {
                anchors.fill: parent
                sourceComponent: win.view === "grid" ? tileC : rowC
            }
            DragHandler {
                id: dh
                target: null
                acceptedDevices: PointerDevice.Mouse | PointerDevice.Stylus
                acceptedButtons: Qt.LeftButton
                onActiveChanged: {
                    const g = cell.mapToItem(null, centroid.position.x, centroid.position.y);
                    if (active) {
                        pane.win.focusPane(pane);
                        if (!pane.isSel(cell.modelData.path))
                            pane.sel = [cell.modelData.path];
                        pane.win.dragStart(pane.sel.slice());
                        pane.win.dragMove(g.x, g.y);
                    } else if (pane.win.dragOn) {
                        pane.win.dragEnd(g.x, g.y, (Qt.application.keyboardModifiers & Qt.ControlModifier) !== 0);
                    }
                }
                onCentroidChanged: {
                    if (active) {
                        const g = cell.mapToItem(null, centroid.position.x, centroid.position.y);
                        pane.win.dragMove(g.x, g.y);
                    }
                }
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: cell.held = false
                onClicked: mouse => {
                    if (cell.held) {
                        cell.held = false;
                        return;
                    }
                    if (mouse.button === Qt.RightButton) {
                        pane.win.focusPane(pane);
                        if (!pane.isSel(cell.modelData.path))
                            pane.sel = [cell.modelData.path];
                        pane.cursor = cell.index;
                        const p = cell.mapToItem(null, mouse.x, mouse.y);
                        pane.win.itemMenu(pane, p.x, p.y);
                    } else {
                        pane.tap(cell.index, mouse.modifiers);
                    }
                }
                onDoubleClicked: mouse => {
                    if (!pane.win.singleClick && mouse.button === Qt.LeftButton)
                        pane.open(cell.modelData);
                }
            }
            TapHandler {
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.WithinBounds
                longPressThreshold: 0.5
                onLongPressed: {
                    cell.held = true;
                    pane.win.focusPane(pane);
                    if (!pane.isSel(cell.modelData.path))
                        pane.sel = [cell.modelData.path];
                    pane.anchorIdx = cell.index;
                    pane.cursor = cell.index;
                    const g = cell.mapToItem(null, point.position.x, point.position.y);
                    pane.win.itemMenu(pane, g.x, g.y);
                }
            }

            // Grid tile: tonal card, rounded thumbnail
            Component {
                id: tileC
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 5
                    radius: 24
                    color: cell.picked ? AppTheme.accentSoft : (ma.containsMouse ? AppTheme.cardHigh : AppTheme.card)
                    border.width: cell.picked || cell.isCur || cell.dropT ? 2 : 0
                    border.color: AppTheme.accent
                    scale: ma.pressed ? 0.96 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                    Item {
                        id: th
                        x: 10
                        y: 10
                        width: parent.width - 20
                        height: parent.height - 64
                        RoundImg {
                            anchors.fill: parent
                            visible: cell.k === "image"
                            radius: 16
                            source: cell.k === "image" ? "file://" + cell.modelData.path : ""
                        }
                        RoundImg {
                            id: tvImg
                            anchors.fill: parent
                            visible: (cell.k === "video" || cell.k === "pdf") && ready
                            radius: 16
                            source: (cell.k === "video" || cell.k === "pdf") && pane.thumbOk[cell.modelData.path] ? pane.thumbUrl(cell.modelData.path) : ""
                        }
                        Ico {
                            visible: cell.k !== "image" && !tvImg.visible
                            anchors.centerIn: parent
                            size: Math.min(parent.width, parent.height) * 0.62
                            name: Fx.ico(cell.k)
                            color: cell.k === "folder" ? AppTheme.accent : AppTheme.dim
                        }
                    }
                    Text {
                        x: 8
                        y: th.y + th.height + 6
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                        text: cell.modelData.rel === cell.modelData.name ? cell.modelData.name : cell.modelData.rel
                        elide: Text.ElideMiddle
                        color: AppTheme.text
                        font.pixelSize: 13
                    }
                    Text {
                        x: 8
                        y: th.y + th.height + 26
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                        text: cell.modelData.dir ? "Folder" : Fx.human(cell.modelData.size)
                        elide: Text.ElideRight
                        color: AppTheme.dim
                        font.pixelSize: 11
                    }
                }
            }

            // List / columns row
            Component {
                id: rowC
                Rectangle {
                    readonly property bool cols3: win.view === "columns"
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    radius: cols3 ? 12 : 20
                    color: cell.picked ? (cols3 ? AppTheme.accent : AppTheme.accentSoft) : (ma.containsMouse ? AppTheme.hover : "transparent")
                    border.width: (cell.isCur && !cell.picked) || cell.dropT ? 2 : 0
                    border.color: AppTheme.accent
                    readonly property color ink: cell.picked && cols3 ? AppTheme.accentInk : AppTheme.text
                    readonly property color inkDim: cell.picked && cols3 ? AppTheme.accentInk : AppTheme.dim
                    readonly property real ic: cols3 ? 22 : 34
                    Item {
                        id: ri
                        x: 12
                        y: (parent.height - height) / 2
                        width: parent.ic
                        height: width
                        Ico { anchors.centerIn: parent; size: parent.width; name: Fx.ico(cell.k); color: cell.picked && parent.parent.cols3 ? AppTheme.accentInk : (cell.k === "folder" ? AppTheme.accent : AppTheme.dim) }
                    }
                    Text {
                        x: ri.x + ri.width + 12
                        width: Math.max(40, parent.width - x - (pane.showCols ? 400 : 60))
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: cell.modelData.rel === cell.modelData.name ? cell.modelData.name : cell.modelData.rel
                        elide: Text.ElideMiddle
                        color: parent.ink
                        font.pixelSize: 15
                    }
                    Text {
                        visible: pane.showCols
                        x: parent.width - 380
                        width: 90
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: cell.modelData.dir ? "\u2014" : Fx.human(cell.modelData.size)
                        color: parent.inkDim
                        font.pixelSize: 13
                    }
                    Text {
                        visible: pane.showCols
                        x: parent.width - 290
                        width: 150
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: Fx.date(cell.modelData.mtime)
                        color: parent.inkDim
                        font.pixelSize: 13
                    }
                    Text {
                        visible: pane.showCols
                        x: parent.width - 130
                        width: 120
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: Fx.typeLabel(cell.modelData)
                        elide: Text.ElideRight
                        color: parent.inkDim
                        font.pixelSize: 13
                    }
                    Ico {
                        visible: cell.modelData.dir && win.view === "columns"
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        name: "fwd"
                        size: 16
                        color: parent.inkDim
                    }
                    Text {
                        visible: !pane.showCols && win.view === "list"
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: cell.modelData.dir ? "" : Fx.human(cell.modelData.size)
                        color: parent.inkDim
                        font.pixelSize: 12
                    }
                }
            }
        }

        Text {
            visible: pane.entries.length === 0
            anchors.centerIn: parent
            text: pane.searching ? "No results" : (pane.query !== "" ? "No match" : "Empty")
            color: AppTheme.dim
            font.pixelSize: 18
        }
    }

    // Empty-area interactions: right click / long-press = folder menu, tap clears selection, drag scrolls.
    MouseArea {
        id: bg
        visible: !pane.isPc
        anchors.fill: view
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        property real lastY: 0
        property bool moved: false
        property bool held: false
        onPressed: mouse => {
            const hit = view.indexAt(mouse.x + view.contentX, mouse.y + view.contentY);
            if (hit >= 0) {
                mouse.accepted = false;
                return;
            }
            lastY = mouse.y;
            moved = false;
            held = false;
        }
        onPositionChanged: mouse => {
            const dy = mouse.y - lastY;
            if (Math.abs(dy) > 2)
                moved = true;
            view.contentY = Math.max(0, Math.min(Math.max(0, view.contentHeight - view.height), view.contentY - dy));
            lastY = mouse.y;
        }
        onPressAndHold: mouse => {
            if (!moved) {
                held = true;
                pane.win.focusPane(pane);
                const p = bg.mapToItem(null, mouse.x, mouse.y);
                pane.win.bgMenu(pane, p.x, p.y);
            }
        }
        onClicked: mouse => {
            pane.win.focusPane(pane);
            if (mouse.button === Qt.RightButton) {
                const p = bg.mapToItem(null, mouse.x, mouse.y);
                pane.win.bgMenu(pane, p.x, p.y);
            } else if (!moved && !held) {
                pane.sel = [];
                pane.cursor = -1;
            }
        }
    }

    // ---- This PC dashboard -------------------------------------------------------------------
    Flickable {
        visible: pane.isPc
        anchors.top: bar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        clip: true
        contentWidth: width
        contentHeight: pcc.implicitHeight + 40
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: pcc
            width: parent.width
            spacing: 14
            Text { text: "Devices"; color: AppTheme.dim; font.pixelSize: 14; font.weight: Font.DemiBold; leftPadding: 8; topPadding: 8 }
            Flow {
                width: parent.width
                spacing: 12
                Repeater {
                    model: pane.win.drives
                    Rectangle {
                        id: dc
                        required property var modelData
                        readonly property real frac: modelData.total > 0 ? modelData.used / modelData.total : 0
                        width: Math.min(340, pcc.width)
                        height: 132
                        radius: 28
                        color: AppTheme.card
                        Ico { x: 18; y: 18; size: 40; name: dc.modelData.removable ? "sd" : "drive"; color: AppTheme.accent }
                        Text { x: 70; y: 16; width: parent.width - 86; text: dc.modelData.title; color: AppTheme.text; font.pixelSize: 17; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text {
                            x: 70
                            y: 40
                            width: parent.width - 86
                            text: dc.modelData.mount === "" ? (dc.modelData.fs + " \u00b7 not mounted") : (Fx.human(dc.modelData.total - dc.modelData.used) + " free of " + Fx.human(dc.modelData.total))
                            color: AppTheme.dim
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            x: 18
                            y: 74
                            width: parent.width - 36
                            height: 10
                            radius: 5
                            color: AppTheme.cardHigh
                            Rectangle { width: parent.width * dc.frac; height: parent.height; radius: 5; color: dc.frac > 0.9 ? "#ff8a80" : AppTheme.accent }
                        }
                        Pill {
                            x: 14
                            y: 86
                            height: 38
                            flat: true
                            label: dc.modelData.mount === "" ? "Mount" : "Open"
                            onClicked: dc.modelData.mount === "" ? pane.win.mountDrive(dc.modelData, pane) : pane.go(dc.modelData.mount)
                        }
                        Pill {
                            visible: dc.modelData.mount !== "" && dc.modelData.mount.indexOf("/run/media") === 0
                            x: 100
                            y: 86
                            height: 38
                            flat: true
                            label: "Unmount"
                            onClicked: pane.win.unmountDrive(dc.modelData)
                        }
                    }
                }
            }
            Text { text: "Folders"; color: AppTheme.dim; font.pixelSize: 14; font.weight: Font.DemiBold; leftPadding: 8; topPadding: 8 }
            Flow {
                width: parent.width
                spacing: 12
                Repeater {
                    model: pane.win.places.filter(p => p.n !== "Home" && p.n !== "Trash")
                    Rectangle {
                        id: fc
                        required property var modelData
                        width: 160
                        height: 110
                        radius: 28
                        color: fm.pressed ? AppTheme.cardHigh : AppTheme.card
                        Ico { x: 18; y: 16; size: 44; name: fc.modelData.ico; color: AppTheme.accent }
                        Text { x: 18; y: 70; width: parent.width - 36; text: fc.modelData.n; color: AppTheme.text; font.pixelSize: 16; elide: Text.ElideRight }
                        MouseArea { id: fm; anchors.fill: parent; onClicked: pane.go(fc.modelData.p) }
                    }
                }
            }
        }
    }
}

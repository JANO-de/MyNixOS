import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The home screen: wallpaper + widgets + paged app icons, always behind the windows.
// Show it with `halo-ctl call desktop show` (empty "home" workspace). Long-press empty space
// for the wallpaper menu; long-press an icon/widget to edit (jiggle, drag to reorder).
// Drag one app onto another and hold ~550ms to merge them into a folder; drag onto a folder
// to add to it. Tap a folder to open it.
PanelWindow {
    id: root

    readonly property int dockSpace: Mode.tablet ? 120 : 104
    property string sheet: "" // "", "menu", "wallpapers", "widgets", "settings"
    property point menuAt: Qt.point(0, 0)
    property string openFolder: "" // folder id currently shown in its own sheet, or ""
    property string libCat: "" // App Library category shown in its sheet, or ""
    property string menuFor: "" // eid whose long-press context menu is open, or ""
    property point menuAt2: Qt.point(0, 0)

    // Library drag (long-press an App Library icon, drop on a home page or the dock).
    property var libDragEntry: null
    property string dragFolder: "" // folder the library-style drag started from (drag out / reorder), or ""
    property bool folderHidden: false // finger left the folder: the sheet fades away (Launcher3 ON_EXIT_CLOSE_DELAY)
    property real libGX: 0
    property real libGY: 0

    // Back gesture (UI.back -> backTick) when no shell layer took it: close home-screen layers, then go to page 1.
    Connections {
        target: UI
        function onBackTickChanged() {
            if (!UI.onHome)
                return;
            if (root.menuFor !== "") {
                root.menuFor = "";
            } else if (root.sheet !== "") {
                root.sheet = "";
            } else if (root.openFolder !== "") {
                root.openFolder = "";
            } else if (root.libCat !== "") {
                root.libCat = "";
            } else if (Home.editing) {
                Home.editing = false;
                Home.save();
            } else if (pager.curPage !== 0) {
                pager.goTo(0);
            }
        }
    }

    function libDragBegin(e, gx, gy) {
        libDragEntry = e;
        libGX = gx;
        libGY = gy;
        pager.widgetDrag = true;
    }

    function libDragMove(gx, gy) {
        libGX = gx;
        libGY = gy;
        const hot = pager.dockHit(gx, gy);
        UI.dockDropHot = hot;
        if (hot)
            UI.dockDropIndex = pager.dockIndexAt(gx);
        if (dragFolder !== "" && openFolder === dragFolder) {
            const inside = !folderHidden && folderSheet.contains(folderSheet.mapFromItem(null, gx, gy));
            folderView.dragAt(gx, gy, inside);
            if (inside)
                exitTimer.stop();
            else if (!folderHidden && !exitTimer.running)
                exitTimer.start();
        }
    }

    function folderDragBegin(e, gx, gy) {
        dragFolder = openFolder;
        folderHidden = false;
        libDragBegin(e, gx, gy);
        folderView.dragAt(gx, gy, true);
    }

    function libDragEnd(gx, gy) {
        const e = libDragEntry;
        libDragEntry = null;
        pager.widgetDrag = false;
        UI.dockDropHot = false;
        exitTimer.stop();
        const fid = dragFolder;
        const gone = folderHidden;
        dragFolder = "";
        folderHidden = false;
        folderView.dragDone();
        if (!e)
            return;
        if (fid !== "") {
            // Drag started inside a folder: reorder in place, or take the app out (home page / dock).
            if (!gone && folderSheet.contains(folderSheet.mapFromItem(null, gx, gy))) {
                Home.moveInFolder(fid, e.id, folderView.rankAt(gx, gy));
            } else if (pager.dockHit(gx, gy)) {
                Apps.pinAtVisible(e, UI.dockDropIndex);
                Home.leaveFolder(e.id, true);
                root.openFolder = "";
            } else if (pager.curPage < pager.iconPages) {
                const q = container.mapFromItem(null, gx, gy);
                Home.addToHomeAt(e.id, pager.indexAt(q.x, q.y));
                root.openFolder = "";
            }
            return;
        }
        if (pager.dockHit(gx, gy)) {
            Apps.pinAtVisible(e, UI.dockDropIndex);
        } else if (pager.curPage < pager.iconPages) {
            const p = container.mapFromItem(null, gx, gy);
            Home.addToHomeAt(e.id, pager.indexAt(p.x, p.y));
        } else {
            return;
        }
        root.libCat = "";
    }

    function openMenu(x, y) {
        menuAt = Qt.point(x, y);
        Wallpaper.rescan();
        sheet = "menu";
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-desktop"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
        id: desk
        anchors.fill: parent

        WallpaperView {
            anchors.fill: parent
            spec: Wallpaper.current
        }

        // Soft scrim so icons and widgets stay readable on any wallpaper.
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.18)
        }

        // Done (edit mode)
        Rectangle {
            visible: Home.editing
            anchors.right: parent.right
            anchors.rightMargin: 28
            anchors.top: parent.top
            anchors.topMargin: 30
            z: 5
            width: doneText.implicitWidth + 36
            height: 38
            radius: 19
            color: Theme.accent

            Text {
                id: doneText
                anchors.centerIn: parent
                text: "Done"
                color: Theme.accentInk
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                onClicked: {
                    Home.editing = false;
                    Home.save();
                }
            }
        }

        // Trash (edit mode): drag an icon here and release to remove it from Home.
        Rectangle {
            id: trashZone
            visible: Home.editing
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 22
            z: 5
            width: pager.dragActive && pager.overTrash ? 64 : 52
            height: width
            radius: width / 2
            color: pager.dragActive && pager.overTrash ? "#ff5f5f" : Qt.rgba(1, 1, 1, 0.16)
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: "\uD83D\uDDD1" // 🗑
                font.pixelSize: 22
            }
        }

        // ---- Pages: widgets + icons -----------------------------------------------------------
        Item {
            id: pager
            anchors.top: parent.top
            anchors.topMargin: 76
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.dockSpace + 30
            anchors.left: parent.left
            anchors.right: parent.right

            readonly property int cellW: Home.cellW
            readonly property int cellH: Home.cellH
            readonly property int gap: 16
            readonly property int cols: Math.max(3, Math.floor((width - 80) / cellW))
            readonly property real areaW: cols * cellW
            readonly property real xPad: (width - areaW) / 2
            readonly property real unit: Math.max(110, Math.min(200, (areaW - 3 * gap) / 4))
            // Widget band (card + room for the "+" chips in edit mode); constant so editing never reflows icons.
            // Icons on page 1 start right below the lowest widget placed there (whole-pixel band, never the full page).
            readonly property real widgetsH: {
                let b = 0;
                for (const w of Home.winst)
                    if (w.page === 0)
                        b = Math.max(b, w.fy * height + w.h * unit + (w.h - 1) * gap);
                return b > 0 ? Math.ceil(Math.min(height - cellH, b + 12)) : 0;
            }
            readonly property int rowsFull: Math.max(1, Math.floor(height / cellH))
            readonly property int rows0: Math.max(1, Math.floor((height - widgetsH) / cellH))
            readonly property int cap0: cols * rows0
            readonly property int capN: cols * rowsFull
            readonly property int n: Home.icons.count
            readonly property int iconPages: n <= cap0 ? 1 : 1 + Math.ceil((n - cap0) / capN)
            readonly property int pageCount: iconPages + 1 // + the App Library page
            readonly property int curPage: Math.max(0, Math.min(pageCount - 1, Math.round(flick.contentX / Math.max(1, width))))

            property bool dragActive: false
            property bool widgetDrag: false
            property var dragSlot: null
            property real fx: 0
            property real fy: 0

            // Drag-to-merge: the slot index currently dwelt on, plus its eid (looked up fresh at
            // merge/release time so a shift during the 550ms dwell can't merge the wrong icon).
            // Crossing into a new index arms mergeTimer; if the finger lingers there it merges
            // into a folder, otherwise it settles as a plain reorder (refreshDrag / mergeTimer / Slot.finish()).
            property var mergeTarget: null
            property string mergeTargetEid: ""
            property bool overTrash: false
            property bool overDock: false // an icon is held over the dock: release = pin it there

            function slotOf(i) {
                let p = 0;
                let k = i;
                if (i >= cap0) {
                    const j = i - cap0;
                    p = 1 + Math.floor(j / capN);
                    k = j % capN;
                }
                return { page: p, col: k % cols, row: Math.floor(k / cols) };
            }
            function slotX(i) {
                const s = slotOf(i);
                return s.page * width + xPad + s.col * cellW;
            }
            function slotY(i) {
                const s = slotOf(i);
                return (s.page === 0 ? widgetsH : 0) + s.row * cellH;
            }
            function indexAt(px, py) {
                const p = Math.max(0, Math.min(iconPages - 1, Math.floor(px / width)));
                const col = Math.max(0, Math.min(cols - 1, Math.floor((px - p * width - xPad) / cellW)));
                const rows = p === 0 ? rows0 : rowsFull;
                const row = Math.max(0, Math.min(rows - 1, Math.floor((py - (p === 0 ? widgetsH : 0)) / cellH)));
                const k = row * cols + col;
                return Math.max(0, Math.min(n - 1, p === 0 ? k : cap0 + (p - 1) * capN + k));
            }

            function dockHit(x, y) {
                const r = UI.dockRect;
                return r.width > 0 && x >= r.x - 48 && x <= r.x + r.width + 48 && y >= r.y - 56;
            }
            // Insertion position among the dock's pinned items for a finger at screen x.
            function dockIndexAt(px) {
                const n = Apps.items.filter(i => i.pinIndex >= 0).length;
                const icon = UI.dockStep - 14;
                const i = Math.ceil((px - UI.dockRowLeft - UI.dockLead - icon / 2) / Math.max(1, UI.dockStep));
                return Math.max(0, Math.min(n, i));
            }

            // Follow the finger, dwell-reorder/merge live, auto-flip pages at the screen edges.
            function refreshDrag() {
                const s = dragSlot;
                if (!s)
                    return;
                const p = container.mapFromItem(null, fx, fy);
                s.dragX = p.x - s.grabX;
                s.dragY = p.y - s.grabY;

                overTrash = trashZone.contains(trashZone.mapFromItem(null, fx, fy));
                if (overTrash) {
                    overDock = false;
                    UI.dockDropHot = false;
                    mergeTarget = null;
                    mergeTargetEid = "";
                    mergeTimer.stop();
                    edgeTimer.stop();
                    return;
                }

                // Over the dock: folders cannot be pinned, plain apps can.
                overDock = !(s.entry && s.entry.isFolder) && dockHit(fx, fy);
                UI.dockDropHot = overDock;
                if (overDock) {
                    UI.dockDropIndex = dockIndexAt(fx);
                    mergeTarget = null;
                    mergeTargetEid = "";
                    mergeTimer.stop();
                    edgeTimer.stop();
                    return;
                }

                const target = indexAt(p.x, p.y);
                if (target !== s.index) {
                    if (target !== mergeTarget) {
                        if (mergeTarget !== null && mergeTarget !== s.index)
                            Home.moveIcon(s.index, mergeTarget);
                        mergeTarget = target;
                        mergeTargetEid = Home.icons.get(target).eid;
                        mergeTimer.restart();
                    }
                } else {
                    mergeTarget = null;
                    mergeTargetEid = "";
                    mergeTimer.stop();
                }

                const vx = pager.mapFromItem(null, fx, fy).x;
                const atEdge = vx < 70 || vx > width - 70;
                if (atEdge && !edgeTimer.running)
                    edgeTimer.start();
                else if (!atEdge)
                    edgeTimer.stop();
            }

            function goTo(p) {
                const t = Math.max(0, Math.min(pageCount - 1, p));
                snapAnim.stop();
                snapAnim.from = flick.contentX;
                snapAnim.to = t * width;
                snapAnim.start();
            }

            onPageCountChanged: if (curPage >= pageCount) goTo(pageCount - 1)
            onCurPageChanged: {
                if (curPage !== iconPages && UI.libSearchOpen) {
                    UI.libSearchOpen = false;
                    Kbd.hideQuiet();
                }
            }

            Timer {
                id: edgeTimer
                interval: 650
                onTriggered: {
                    const vx = pager.mapFromItem(null, pager.fx, pager.fy).x;
                    if (vx < 70)
                        pager.goTo(pager.curPage - 1);
                    else if (vx > pager.width - 70)
                        pager.goTo(Math.min(pager.curPage + 1, pager.iconPages - 1));
                }
            }

            // Dwell on one target slot long enough -> merge into a folder instead of reordering.
            Timer {
                id: mergeTimer
                interval: 550
                onTriggered: {
                    const s = pager.dragSlot;
                    if (!s || !pager.mergeTargetEid)
                        return;
                    const dragIdx = Home.indexOfIcon(s.eid);
                    const targetIdx = Home.indexOfIcon(pager.mergeTargetEid);
                    if (dragIdx < 0 || targetIdx < 0 || dragIdx === targetIdx)
                        return;
                    Home.mergeIntoFolder(dragIdx, targetIdx);
                    pager.mergeTarget = null;
                    pager.mergeTargetEid = "";
                    pager.dragActive = false;
                    pager.dragSlot = null;
                    edgeTimer.stop();
                }
            }

            NumberAnimation {
                id: snapAnim
                target: flick
                property: "contentX"
                duration: 160
                easing.type: Easing.OutCubic
            }

            Flickable {
                id: flick
                anchors.fill: parent
                clip: true
                contentWidth: pager.width * pager.pageCount
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                interactive: !pager.dragActive && !pager.widgetDrag
                boundsBehavior: Flickable.DragAndOvershootBounds

                onMovementStarted: snapAnim.stop()
                onContentXChanged: if (pager.dragActive) pager.refreshDrag()
                property real dragStartX: 0
                onDragStarted: dragStartX = contentX
                onDragEnded: {
                    // Direction from flick speed, else from how far the finger dragged (>12% of a page).
                    const v = horizontalVelocity;
                    const d = contentX - dragStartX;
                    let dir = 0;
                    if (Math.abs(v) > 250)
                        dir = v > 0 ? 1 : -1;
                    else if (Math.abs(d) > pager.width * 0.12)
                        dir = d > 0 ? 1 : -1;
                    cancelFlick();
                    pager.goTo(Math.round(dragStartX / pager.width) + dir);
                }
                // Never rest between two pages.
                onMovementEnded: {
                    if (!snapAnim.running && !pager.dragActive)
                        pager.goTo(Math.round(contentX / pager.width));
                }

                Item {
                    id: container
                    width: flick.contentWidth
                    height: flick.height

                    // Empty space: tap leaves edit mode, long-press opens the wallpaper menu.
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.menuFor = "";
                            UI.dockEditing = false;
                            if (Home.editing)
                                Home.editing = false;
                        }
                        onPressAndHold: mouse => {
                            if (Home.editing)
                                return;
                            const p = mapToItem(desk, mouse.x, mouse.y);
                            root.openMenu(p.x, p.y);
                        }
                    }

                    // Widgets: free placement on any icon page (move/resize in edit mode).
                    Repeater {
                        model: Home.winst

                        WidgetHost {
                            required property var modelData
                            inst: modelData
                            unit: pager.unit
                            gap: pager.gap
                            pw: pager.width
                            ph: pager.height
                            xPad: pager.xPad
                            pagerItem: pager
                            flickRef: flick
                            maxPage: pager.iconPages
                            onConfigure: {
                                Home.pickFor = modelData.id;
                                root.sheet = "pick";
                            }
                            onWantPage: d => pager.goTo(Math.max(0, Math.min(pager.pageCount - 1, pager.curPage + d)))
                            onDraggingChanged: pager.widgetDrag = dragging
                        }
                    }

                    // App Library (last page): all apps by category, tap a card to open it.
                    Item {
                        id: libPage
                        x: pager.iconPages * pager.width
                        width: pager.width
                        height: container.height

                        readonly property string q: UI.libQuery
                        readonly property var results: {
                            const t = q.trim().toLowerCase();
                            if (t === "")
                                return [];
                            const out = [];
                            const seen = {};
                            for (const c of Home.libCats)
                                for (const e of c.items) {
                                    if (seen[e.id])
                                        continue;
                                    const hay = (String(e.name) + " " + String(e.genericName || "") + " " + String(e.comment || "")).toLowerCase();
                                    if (hay.indexOf(t) >= 0) {
                                        seen[e.id] = true;
                                        out.push(e);
                                    }
                                }
                            out.sort((a, b) => String(a.name).toLowerCase().indexOf(t) - String(b.name).toLowerCase().indexOf(t) || String(a.name).localeCompare(String(b.name)));
                            return out;
                        }
                        readonly property int cols: pager.areaW > 900 ? 3 : 2
                        readonly property real cardW: (pager.areaW - (cols - 1) * 18) / cols

                        Text {
                            x: pager.xPad
                            y: 4
                            text: "App Library"
                            color: Theme.text
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                        }

                        // Search pill: tapping opens the LibSearch bar (its own window, so it can take keyboard focus).
                        Rectangle {
                            x: pager.xPad + 230
                            y: 0
                            width: pager.areaW - 230
                            height: 44
                            radius: 22
                            color: Qt.rgba(1, 1, 1, 0.12)
                            border.width: UI.libSearchOpen ? 2 : 0
                            border.color: Theme.accent

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 18
                                width: parent.width - 70
                                elide: Text.ElideRight
                                text: UI.libQuery !== "" ? UI.libQuery : "Search apps"
                                color: UI.libQuery !== "" ? Theme.text : Theme.dim
                                font.pixelSize: 18
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: UI.libSearchOpen = true
                            }
                            Rectangle {
                                visible: UI.libQuery !== ""
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                height: 30
                                radius: 15
                                color: Qt.rgba(1, 1, 1, 0.2)
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u2715"
                                    color: Theme.text
                                    font.pixelSize: 13
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    onClicked: UI.libQuery = ""
                                }
                            }
                        }

                        // Search results (long-press + drag an icon to put it on the home screen or dock)
                        Flickable {
                            visible: libPage.q.trim() !== ""
                            x: pager.xPad
                            y: 52
                            width: pager.areaW
                            height: libPage.height - 60
                            contentHeight: resFlow.height + 24
                            clip: true
                            flickableDirection: Flickable.VerticalFlick
                            boundsBehavior: Flickable.StopAtBounds

                            Flow {
                                id: resFlow
                                width: parent.width
                                spacing: 6

                                Repeater {
                                    model: libPage.results

                                    LibItem {
                                        required property var modelData
                                        width: Home.cellW
                                        height: Home.cellH
                                        entry: modelData
                                        onActivated: {
                                            UI.libSearchOpen = false;
                                            Kbd.hideQuiet();
                                            Home.launch(modelData);
                                        }
                                        onDragBegan: (gx, gy) => root.libDragBegin(modelData, gx, gy)
                                        onDragMoved: (gx, gy) => root.libDragMove(gx, gy)
                                        onDragEnded: (gx, gy) => root.libDragEnd(gx, gy)
                                    }
                                }
                            }
                            Text {
                                visible: libPage.results.length === 0
                                text: "No apps found"
                                color: Theme.dim
                                font.pixelSize: 16
                            }
                        }

                        Flickable {
                            visible: libPage.q.trim() === ""
                            x: pager.xPad
                            y: 52
                            width: pager.areaW
                            height: libPage.height - 60
                            contentHeight: libFlow.height + 24
                            clip: true
                            flickableDirection: Flickable.VerticalFlick
                            boundsBehavior: Flickable.StopAtBounds

                            Flow {
                                id: libFlow
                                width: parent.width
                                spacing: 18

                                Repeater {
                                    model: Home.libCats

                                    Rectangle {
                                        id: card
                                        required property var modelData
                                        width: libPage.cardW
                                        height: libPage.cardW * 0.78
                                        radius: 30
                                        color: Theme.glass
                                        border.color: Theme.glassStroke
                                        border.width: 1
                                        scale: cardTap.pressed ? 0.97 : 1
                                        Behavior on scale { NumberAnimation { duration: 100 } }

                                        Grid {
                                            x: 20
                                            y: 20
                                            columns: 2
                                            spacing: 10

                                            Repeater {
                                                model: card.modelData.items.slice(0, 4)

                                                Image {
                                                    required property var modelData
                                                    width: card.width * 0.2
                                                    height: width
                                                    source: Apps.iconSource(modelData.icon)
                                                    sourceSize: Qt.size(96, 96)
                                                    fillMode: Image.PreserveAspectFit
                                                    smooth: true
                                                }
                                            }
                                        }

                                        Text {
                                            x: 20
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 16
                                            text: card.modelData.title + "  \u00b7  " + card.modelData.items.length
                                            color: Theme.text
                                            font.pixelSize: 15
                                            font.weight: Font.DemiBold
                                        }

                                        MouseArea {
                                            id: cardTap
                                            anchors.fill: parent
                                            onClicked: root.libCat = card.modelData.title
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Icons
                    Repeater {
                        model: Home.icons

                        delegate: Item {
                            id: slot

                            required property int index
                            required property string eid

                            property bool dragging: false
                            property real dragX: 0
                            property real dragY: 0
                            property real grabX: 0
                            property real grabY: 0
                            property real pressX: 0
                            property real pressY: 0
                            property real menuPressX: 0
                            property real menuPressY: 0
                            readonly property var entry: Home.entry(eid)

                            function begin() {
                                const s = mapToItem(null, pressX, pressY);
                                const here = mapToItem(container, 0, 0);
                                grabX = pressX;
                                grabY = pressY;
                                dragX = here.x;
                                dragY = here.y;
                                pager.fx = s.x;
                                pager.fy = s.y;
                                pager.dragSlot = slot;
                                pager.dragActive = true;
                                dragging = true;
                            }

                            function finish() {
                                if (!dragging)
                                    return;
                                dragging = false;
                                pager.dragActive = false;
                                if (pager.overDock) {
                                    // Pin to the dock; the icon stays on the home screen too.
                                    if (entry && !entry.isFolder)
                                        Apps.pinAtVisible(entry, UI.dockDropIndex);
                                } else if (pager.overTrash) {
                                    Home.hideIconAt(index);
                                } else if (pager.mergeTargetEid) {
                                    // If released mid-hover (before the merge dwell fired), settle it as a plain reorder.
                                    const t = Home.indexOfIcon(pager.mergeTargetEid);
                                    if (t >= 0 && t !== index)
                                        Home.moveIcon(index, t);
                                }
                                pager.overTrash = false;
                                pager.overDock = false;
                                UI.dockDropHot = false;
                                pager.mergeTarget = null;
                                pager.mergeTargetEid = "";
                                mergeTimer.stop();
                                pager.dragSlot = null;
                                edgeTimer.stop();
                                Home.save();
                            }

                            visible: entry !== null && entry !== undefined
                            width: pager.cellW
                            height: pager.cellH
                            x: dragging ? dragX : pager.slotX(index)
                            y: dragging ? dragY : pager.slotY(index)
                            z: dragging ? 10 : 0
                            scale: dragging ? 1.1 : (tap.pressed && !Home.editing ? 0.92 : 1)

                            Behavior on x { enabled: !slot.dragging; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            Behavior on y { enabled: !slot.dragging; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            SequentialAnimation on rotation {
                                running: Home.editing && !slot.dragging
                                loops: Animation.Infinite
                                NumberAnimation { to: 1.6; duration: 100 }
                                NumberAnimation { to: -1.6; duration: 100 }
                                onRunningChanged: if (!running) slot.rotation = 0
                            }

                            AppIcon {
                                anchors.fill: parent
                                entry: slot.entry
                                interactive: false
                            }

                            MouseArea {
                                id: tap
                                anchors.fill: parent
                                preventStealing: slot.dragging

                                onPressed: mouse => {
                                    slot.pressX = mouse.x;
                                    slot.pressY = mouse.y;
                                    if (Home.editing)
                                        slot.begin();
                                }
                                onPositionChanged: mouse => {
                                    slot.pressX = mouse.x;
                                    slot.pressY = mouse.y;
                                    if (root.menuFor === slot.eid
                                        && (Math.abs(mouse.x - slot.menuPressX) > 14 || Math.abs(mouse.y - slot.menuPressY) > 14))
                                        root.menuFor = "";
                                    if (!slot.dragging)
                                        return;
                                    const s = mapToItem(null, mouse.x, mouse.y);
                                    pager.fx = s.x;
                                    pager.fy = s.y;
                                    pager.refreshDrag();
                                }
                                onPressAndHold: mouse => {
                                    if (!Home.editing) {
                                        Home.editing = true;
                                        slot.begin();
                                        slot.menuPressX = mouse.x;
                                        slot.menuPressY = mouse.y;
                                        root.menuFor = slot.eid;
                                        root.menuAt2 = mapToItem(desk, width / 2, 0);
                                    }
                                }
                                onClicked: {
                                    if (!Home.editing && slot.entry) {
                                        if (slot.entry.isFolder)
                                            root.openFolder = slot.eid;
                                        else
                                            Home.launch(slot.entry);
                                    }
                                }
                                onReleased: slot.finish()
                                onCanceled: slot.finish()
                            }
                        }
                    }

                    // Drop highlight while an icon dwells on another one (Launcher3 FolderRingAnimator): a ring grows behind the target.
                    Rectangle {
                        id: mergeRing
                        readonly property int ti: (pager.dragActive && pager.mergeTargetEid !== "" && !pager.overDock && !pager.overTrash) ? Home.indexOfIcon(pager.mergeTargetEid) : -1
                        readonly property real colH: Home.tile + (Home.showLabels ? 25 : 0)
                        readonly property real size: Home.tile * 1.3
                        z: -1
                        width: size
                        height: size
                        radius: size / 4
                        color: Qt.rgba(1, 1, 1, 0.26)
                        visible: opacity > 0.01
                        opacity: ti >= 0 ? 1 : 0
                        scale: ti >= 0 ? 1 : 0.75
                        x: pager.slotX(Math.max(0, ti)) + (pager.cellW - size) / 2
                        y: pager.slotY(Math.max(0, ti)) + (pager.cellH - colH) / 2 + Home.tile / 2 - size / 2
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    }
                }
            }
        }

        // Edit mode chips (kept out of the scrolling page so they never push icons around)
        // Edit mode: open the widget gallery
        Rectangle {
            id: addBtn
            visible: Home.editing
            x: pager.xPad
            y: 22
            z: 6
            width: addText.implicitWidth + 36
            height: 36
            radius: 18
            color: Theme.accent

            Text {
                id: addText
                anchors.centerIn: parent
                text: "+  Add widget"
                color: Theme.accentInk
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.sheet = "widgets"
            }
        }

        // Edit mode: free move vs snap to grid
        Rectangle {
            visible: Home.editing
            x: pager.xPad + addBtn.width + 10
            y: 22
            z: 6
            width: snapText.implicitWidth + 36
            height: 36
            radius: 18
            color: Home.snapGrid ? Theme.accent : Qt.rgba(1, 1, 1, 0.16)

            Text {
                id: snapText
                anchors.centerIn: parent
                text: Home.snapGrid ? "Snap to grid: on" : "Free move"
                color: Home.snapGrid ? Theme.accentInk : Theme.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Home.snapGrid = !Home.snapGrid;
                    Home.save();
                }
            }
        }


        // Page dots
        Row {
            visible: pager.pageCount > 1
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.dockSpace + 6
            spacing: 10

            Repeater {
                model: pager.pageCount

                Rectangle {
                    required property int index
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.text
                    opacity: index === pager.curPage ? 0.95 : 0.35
                    scale: index === pager.curPage ? 1.15 : 1
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Behavior on scale { NumberAnimation { duration: 160 } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        onClicked: pager.goTo(parent.index)
                    }
                }
            }
        }

        // Per-icon context menu (long-press). Non-modal so jiggle/drag keeps working.
        Column {
            id: iconMenu
            visible: root.menuFor !== ""
            z: 6
            width: 230
            spacing: 4
            x: Math.max(12, Math.min(desk.width - width - 12, root.menuAt2.x - width / 2))
            y: Math.max(60, Math.min(desk.height - height - 12, root.menuAt2.y - height - 8))

            Rectangle {
                width: parent.width
                height: 44
                radius: 14
                color: openTap.pressed ? Theme.surfacePress : Theme.surfaceHigh
                Text {
                    anchors.centerIn: parent
                    text: "Open"
                    color: Theme.text
                    font.pixelSize: 15
                }
                MouseArea {
                    id: openTap
                    anchors.fill: parent
                    onClicked: {
                        const id = root.menuFor;
                        const e = Home.entry(id);
                        root.menuFor = "";
                        Home.editing = false;
                        if (!e)
                            return;
                        if (e.isFolder)
                            root.openFolder = id;
                        else
                            Home.launch(e);
                    }
                }
            }

            // Same split options as the dock menu (Android TaskbarPopupController); nothing in front -> staging.
            Repeater {
                model: Mode.tablet && !Home.isFolder(root.menuFor) ? ["left", "right"] : []

                Rectangle {
                    id: splitRow
                    required property string modelData
                    width: iconMenu.width
                    height: 44
                    radius: 14
                    color: splitTap.pressed ? Theme.surfacePress : Theme.surfaceHigh
                    Text {
                        anchors.centerIn: parent
                        text: splitRow.modelData === "left" ? "Split left" : "Split right"
                        color: Theme.text
                        font.pixelSize: 15
                    }
                    MouseArea {
                        id: splitTap
                        anchors.fill: parent
                        onClicked: {
                            const e = Home.entry(root.menuFor);
                            root.menuFor = "";
                            Home.editing = false;
                            if (!e)
                                return;
                            const it = Apps.items.find(i => i.entry && i.entry.id === e.id)
                                || { key: "launch:" + e.id, pinIndex: -1, entry: e, windows: [], name: e.name, icon: e.icon };
                            UI.splitFromMenu(it, splitRow.modelData, root.screen);
                        }
                    }
                }
            }

            Rectangle {
                visible: !Home.isFolder(root.menuFor)
                width: parent.width
                height: 44
                radius: 14
                color: infoTap.pressed ? Theme.surfacePress : Theme.surfaceHigh
                Text {
                    anchors.centerIn: parent
                    text: "App info"
                    color: Theme.text
                    font.pixelSize: 15
                }
                MouseArea {
                    id: infoTap
                    anchors.fill: parent
                    onClicked: {
                        const e = Home.entry(root.menuFor);
                        root.menuFor = "";
                        Home.editing = false;
                        UI.openAppInfo(e ? e.id : "");
                    }
                }
            }

            Rectangle {
                visible: Home.isFolder(root.menuFor)
                width: parent.width
                height: 44
                radius: 14
                color: renameTap.pressed ? Theme.surfacePress : Theme.surfaceHigh
                Text {
                    anchors.centerIn: parent
                    text: "Rename"
                    color: Theme.text
                    font.pixelSize: 15
                }
                MouseArea {
                    id: renameTap
                    anchors.fill: parent
                    onClicked: {
                        root.openFolder = root.menuFor;
                        root.menuFor = "";
                        Home.editing = false;
                    }
                }
            }

            Rectangle {
                visible: !Home.isFolder(root.menuFor)
                width: parent.width
                height: 44
                radius: 14
                color: dockMenuTap.pressed ? Theme.surfacePress : Theme.surfaceHigh
                Text {
                    anchors.centerIn: parent
                    text: Apps.isPinned(Home.entry(root.menuFor)) ? "Remove from Dock" : "Add to Dock"
                    color: Theme.text
                    font.pixelSize: 15
                }
                MouseArea {
                    id: dockMenuTap
                    anchors.fill: parent
                    onClicked: {
                        const e = Home.entry(root.menuFor);
                        root.menuFor = "";
                        if (e) {
                            if (Apps.isPinned(e))
                                Apps.unpinEntry(e);
                            else
                                Apps.pin(e);
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 44
                radius: 14
                color: removeTap.pressed ? Qt.rgba(0.4, 0.15, 0.15, 0.98) : Qt.rgba(0.25, 0.1, 0.1, 0.97)
                Text {
                    anchors.centerIn: parent
                    text: "Remove from Home Screen"
                    color: "#ff8f8f"
                    font.pixelSize: 14
                }
                MouseArea {
                    id: removeTap
                    anchors.fill: parent
                    onClicked: {
                        const idx = Home.indexOfIcon(root.menuFor);
                        root.menuFor = "";
                        if (idx >= 0)
                            Home.hideIconAt(idx);
                    }
                }
            }
        }

        // Library drag: ghost icon, drop marker on the home page, edge page flip.
        Rectangle {
            visible: root.libDragEntry !== null && pager.curPage < pager.iconPages && !pager.dockHit(root.libGX, root.libGY)
            readonly property int ti: visible ? pager.indexAt(container.mapFromItem(null, root.libGX, root.libGY).x, container.mapFromItem(null, root.libGX, root.libGY).y) : 0
            x: pager.mapToItem(desk, pager.slotX(ti) - flick.contentX, pager.slotY(ti)).x
            y: pager.mapToItem(desk, pager.slotX(ti) - flick.contentX, pager.slotY(ti)).y
            width: pager.cellW
            height: pager.cellH
            radius: 24
            color: Qt.rgba(1, 1, 1, 0.12)
            border.color: Theme.accent
            border.width: 2
            z: 25
        }
        Item {
            visible: root.libDragEntry !== null
            x: root.libGX - 44
            y: root.libGY - 44
            width: 88
            height: 88
            z: 30
            scale: 1.1

            Rectangle {
                anchors.fill: parent
                radius: 22
                color: Theme.iconTile
            }
            Image {
                anchors.centerIn: parent
                width: 62
                height: 62
                source: root.libDragEntry ? Apps.iconSource(root.libDragEntry.icon) : ""
                sourceSize: Qt.size(128, 128)
                fillMode: Image.PreserveAspectFit
            }
        }
        Timer {
            interval: 700
            repeat: true
            running: root.libDragEntry !== null && (root.libGX < 70 || root.libGX > desk.width - 70)
            onTriggered: pager.goTo(pager.curPage + (root.libGX < 70 ? -1 : 1))
        }

        // ---- Long-press menu and sheets ----------------------------------------------------------
        Item {
            id: overlay
            anchors.fill: parent
            z: 20
            visible: root.sheet !== "" || root.openFolder !== "" || root.libCat !== "" || dim.opacity > 0.01

            Rectangle {
                id: dim
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.4)
                opacity: (root.sheet !== "" || root.openFolder !== "" || root.libCat !== "") && !root.libDragEntry ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.sheet = "";
                        root.openFolder = "";
                        root.libCat = "";
                    }
                }
            }

            // Wallpaper menu (Android-launcher style)
            Column {
                id: menu
                visible: root.sheet === "menu"
                width: Math.min(overlay.width - 48, 560)
                spacing: 8
                x: Math.max(24, Math.min(overlay.width - width - 24, root.menuAt.x - width / 2))
                y: Math.max(40, Math.min(overlay.height - height - 40, root.menuAt.y - height / 2))
                scale: root.sheet === "menu" ? 1 : 0.92
                opacity: root.sheet === "menu" ? 1 : 0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 160 } }

                Rectangle {
                    width: parent.width
                    height: thumbs.height + 32
                    radius: 36
                    color: Theme.surfaceHigh

                    Row {
                        id: thumbs
                        anchors.centerIn: parent
                        spacing: 12

                        Repeater {
                            model: Wallpaper.quick(4)

                            Item {
                                required property string modelData
                                readonly property real tw: (menu.width - 32 - 3 * 12) / 4
                                width: tw
                                height: tw * 1.35

                                WallpaperView {
                                    anchors.fill: parent
                                    spec: parent.modelData
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    color: "transparent"
                                    border.width: parent.modelData === Wallpaper.current ? 3 : 1
                                    border.color: parent.modelData === Wallpaper.current ? "#a6f0a6" : Theme.glassStroke
                                }
                                Rectangle {
                                    visible: parent.modelData === Wallpaper.current
                                    anchors.centerIn: parent
                                    width: 44
                                    height: 44
                                    radius: 22
                                    color: "#a6f0a6"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "#102010"
                                        font.pixelSize: 22
                                        font.weight: Font.Bold
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Wallpaper.set(parent.modelData)
                                }
                            }
                        }
                    }
                }

                Repeater {
                    model: [
                        { glyph: "✎", label: "Edit home screen", target: "edit-home" },
                        { glyph: "▣", label: "Wallpapers", target: "wallpapers" },
                        { glyph: "⊞", label: "Widgets", target: "widgets" },
                        { glyph: "⚙", label: "Halo Settings", target: "halo-settings" },
                        { glyph: "⌂", label: "Launcher settings", target: "settings" }
                    ]

                    Rectangle {
                        required property var modelData
                        width: menu.width
                        height: 64
                        radius: 28
                        color: rowTap.pressed ? Theme.surfacePress : Theme.surfaceHigh
                        Behavior on color { ColorAnimation { duration: 90 } }

                        Text {
                            x: 28
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData.glyph
                            color: Theme.text
                            font.pixelSize: 24
                        }
                        Text {
                            x: 84
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData.label
                            color: Theme.text
                            font.pixelSize: 18
                        }
                        MouseArea {
                            id: rowTap
                            anchors.fill: parent
                            onClicked: {
                                if (parent.modelData.target === "edit-home") {
                                    root.sheet = "";
                                    Home.editing = true;
                                } else if (parent.modelData.target === "halo-settings") {
                                    root.sheet = "";
                                    UI.openSettings();
                                } else {
                                    root.sheet = parent.modelData.target;
                                }
                            }
                        }
                    }
                }
            }

            // Wallpapers sheet
            Sheet {
                visible: root.sheet === "wallpapers"
                anchors.centerIn: parent
                title: "Wallpapers"
                onClosed: root.sheet = "menu"

                Flow {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: root.sheet === "wallpapers" ? Wallpaper.specs : []

                        Item {
                            required property string modelData
                            width: (parent.width - 36) / 4
                            height: width * 1.35

                            WallpaperView {
                                anchors.fill: parent
                                spec: parent.modelData
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: "transparent"
                                border.width: parent.modelData === Wallpaper.current ? 3 : 1
                                border.color: parent.modelData === Wallpaper.current ? "#a6f0a6" : Theme.glassStroke
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Wallpaper.set(parent.modelData)
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        topPadding: 8
                        text: "Add your own images to ~/Pictures/Wallpapers"
                        color: Theme.dim
                        font.pixelSize: 13
                    }
                }
            }

            // Widgets gallery: Add places a new copy on the current page (any number of each).
            Sheet {
                visible: root.sheet === "widgets"
                anchors.centerIn: parent
                title: "Widgets"
                onClosed: root.sheet = Home.editing ? "" : "menu"

                Flow {
                    width: parent.width
                    spacing: 14

                    Repeater {
                        model: root.sheet === "widgets" ? Home.widgetTypes : []

                        Column {
                            required property var modelData
                            width: Math.min(300, modelData.w * 150 + (modelData.w - 1) * 14)
                            spacing: 8

                            WidgetHost {
                                preview: true
                                inst: ({ id: "", type: parent.modelData.id, page: 0, fx: 0, fy: 0, w: parent.modelData.w, h: parent.modelData.h, cfg: ({}) })
                                width: parent.width
                                height: 150
                            }
                            Rectangle {
                                width: parent.width
                                height: 36
                                radius: 18
                                color: Theme.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: "Add " + parent.parent.modelData.title
                                    color: Theme.accentInk
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Home.addWidget(parent.parent.modelData.id, pager.curPage >= pager.iconPages ? -1 : pager.curPage);
                                        Home.editing = true;
                                        root.sheet = "";
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        topPadding: 6
                        text: "Widgets go anywhere: long-press one, drag it, resize with the corner handle. Stickers and photo frames use the pencil."
                        color: Theme.dim
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                    }
                }
            }

            // Widget picker (photos / sticker / app)
            Sheet {
                visible: root.sheet === "pick"
                anchors.centerIn: parent
                title: "Customize widget"
                onClosed: root.sheet = ""

                Item {
                    width: parent.width
                    height: 460

                    Loader {
                        anchors.fill: parent
                        active: root.sheet === "pick"
                        sourceComponent: WidgetPicker {
                            onDone: root.sheet = ""
                        }
                    }
                }
            }

            // Launcher settings
            Sheet {
                visible: root.sheet === "settings"
                anchors.centerIn: parent
                title: "Launcher settings"
                onClosed: root.sheet = "menu"

                Column {
                    width: parent.width
                    spacing: 12

                    // Show app names
                    Rectangle {
                        width: parent.width
                        height: 60
                        radius: 24
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            x: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Show app names"
                            color: Theme.text
                            font.pixelSize: 17
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            width: 56
                            height: 32
                            radius: 16
                            color: Home.showLabels ? Theme.accent : Qt.rgba(1, 1, 1, 0.2)
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Rectangle {
                                y: 3
                                x: Home.showLabels ? parent.width - width - 3 : 3
                                width: 26
                                height: 26
                                radius: 13
                                color: "white"
                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Home.showLabels = !Home.showLabels;
                                Home.save();
                            }
                        }
                    }

                    // Icon size
                    Rectangle {
                        width: parent.width
                        height: 84
                        radius: 24
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            x: 24
                            y: 12
                            text: "Icon size"
                            color: Theme.text
                            font.pixelSize: 17
                        }
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 10
                            spacing: 8

                            Repeater {
                                model: ["Small", "Medium", "Large"]

                                Rectangle {
                                    required property int index
                                    required property string modelData
                                    width: 96
                                    height: 30
                                    radius: 15
                                    color: Home.density === index ? Theme.accent : Qt.rgba(1, 1, 1, 0.14)
                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.modelData
                                        color: Home.density === parent.index ? Theme.accentInk : Theme.text
                                        font.pixelSize: 13
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            Home.density = parent.index;
                                            Home.save();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Colour scheme (matugen)
                    Rectangle {
                        width: parent.width
                        height: 52 + schemeFlow.height + 12
                        radius: 24
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            x: 24
                            y: 12
                            text: "Colour scheme"
                            color: Theme.text
                            font.pixelSize: 17
                        }
                        Flow {
                            id: schemeFlow
                            x: 20
                            y: 48
                            width: parent.width - 40
                            spacing: 8

                            Repeater {
                                model: Theme.schemes

                                Rectangle {
                                    required property string modelData
                                    width: schemeText.implicitWidth + 28
                                    height: 30
                                    radius: 15
                                    color: Theme.scheme === modelData ? Theme.accent : Qt.rgba(1, 1, 1, 0.14)
                                    Text {
                                        id: schemeText
                                        anchors.centerIn: parent
                                        text: parent.modelData
                                        color: Theme.scheme === parent.modelData ? Theme.accentInk : Theme.text
                                        font.pixelSize: 13
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: Theme.setScheme(parent.modelData)
                                    }
                                }
                            }
                        }
                    }

                    // Edit
                    Rectangle {
                        width: parent.width
                        height: 60
                        radius: 24
                        color: Qt.rgba(1, 1, 1, 0.08)
                        Text {
                            x: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Edit home screen"
                            color: Theme.text
                            font.pixelSize: 17
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.sheet = "";
                                Home.editing = true;
                            }
                        }
                    }

                    // Reset
                    Rectangle {
                        width: parent.width
                        height: 60
                        radius: 24
                        color: Qt.rgba(1, 0.3, 0.3, 0.14)
                        Text {
                            x: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Reset home layout"
                            color: "#ff8f8f"
                            font.pixelSize: 17
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Home.reset();
                                root.sheet = "";
                            }
                        }
                    }
                }
            }

            // App Library category
            Sheet {
                id: libSheet
                opacity: root.libDragEntry ? 0 : 1
                visible: root.libCat !== ""
                anchors.centerIn: parent
                title: root.libCat

                readonly property var items: {
                    for (const c of Home.libCats)
                        if (c.title === root.libCat)
                            return c.items;
                    return [];
                }
                onClosed: root.libCat = ""

                Flow {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: libSheet.items

                        LibItem {
                            required property var modelData
                            width: Home.cellW
                            height: Home.cellH
                            entry: modelData
                            onActivated: {
                                root.libCat = "";
                                Home.launch(modelData);
                            }
                            onDragBegan: (gx, gy) => root.libDragBegin(modelData, gx, gy)
                            onDragMoved: (gx, gy) => root.libDragMove(gx, gy)
                            onDragEnded: (gx, gy) => root.libDragEnd(gx, gy)
                        }
                    }
                }
            }

            // Folder contents (paged grid, drag to reorder / take out)
            Timer {
                id: exitTimer
                interval: 400 // Launcher3 Folder.ON_EXIT_CLOSE_DELAY (from memory, not verified)
                onTriggered: root.folderHidden = true
            }
            Sheet {
                id: folderSheet
                visible: root.openFolder !== ""
                anchors.centerIn: parent
                title: (Home.folders[root.openFolder] ? Home.folders[root.openFolder].name : "")
                opacity: root.folderHidden ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 140 } }
                onClosed: root.openFolder = ""

                Column {
                    width: parent.width
                    spacing: 16

                    TextInput {
                        width: parent.width
                        horizontalAlignment: folderView.pages > 1 ? TextInput.AlignLeft : TextInput.AlignHCenter
                        text: Home.folders[root.openFolder] ? Home.folders[root.openFolder].name : ""
                        color: Theme.text
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        onEditingFinished: Home.renameFolder(root.openFolder, text)
                    }

                    Item {
                        width: parent.width
                        height: folderView.height

                        FolderView {
                            id: folderView
                            anchors.horizontalCenter: parent.horizontalCenter
                            fid: root.openFolder
                            onItemActivated: e => {
                                root.openFolder = "";
                                Home.launch(e);
                            }
                            onItemDragBegan: (e, gx, gy) => root.folderDragBegin(e, gx, gy)
                            onItemDragMoved: (gx, gy) => root.libDragMove(gx, gy)
                            onItemDragEnded: (gx, gy) => root.libDragEnd(gx, gy)
                        }
                    }

                    Text {
                        width: parent.width
                        text: "Long-press and drag an app to reorder it, or out of the folder onto the home screen or dock."
                        color: Theme.dim
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}

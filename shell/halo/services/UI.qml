pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Shared shell state + IPC entry points.
//   halo-ctl call home|shade|overview toggle|open|close ; halo-ctl call desktop show
Singleton {
    id: root

    property bool homeOpen: false
    property bool shadeOpen: false
    property double shadeOpenedAt: 0
    property bool overviewOpen: false
    property bool settingsOpen: false

    // Dock drag-and-drop.
    //  home screen -> dock: Desktop.qml sets dockDropHot / dockDropIndex while an icon hovers the dock.
    //  dock -> screen: dragging an app up out of the dock shows drop zones (Slide Over at the edge,
    //  Split View further in); see DockDrag.qml and Tiling.qml.
    property bool dockDropHot: false
    property int dockDropIndex: 0
    property rect dockRect: Qt.rect(0, 0, 0, 0) // dock pill in screen coordinates (published by Dock.qml)
    property real dockScreenW: 0
    property real dockScreenH: 0
    property real dockRowLeft: 0
    property real dockLead: 0
    property real dockStep: 1
    property bool dockDragActive: false
    property var dockDragItem: null
    property string dockDragIcon: ""
    property string dockDragScreen: ""
    property real dockDragX: 0
    property real dockDragY: 0
    property string libQuery: "" // App Library search text
    property bool libSearchOpen: false // the search bar window (keyboard focus) is up
    property double inputFocusAt: 0 // last time a SetInput gained focus
    property double inputTapAt: 0 // last press on a SetInput (Settings uses it to tell field taps from other taps)
    property string dockDragZone: "" // "", slide-left, slide-right, split-left, split-right

    // Finger-tracked pulls from the screen edges (see TopEdge.qml / BottomEdge.qml).
    property bool shadeDragging: false
    property real shadeDrag: 0 // 0..1
    property bool overviewDragging: false
    property real overviewDrag: 0 // 0..1
    property bool overviewHomeHint: false // dragged past half the screen inside an app: release = home

    // iPad-style dock reveal: first stretch of the bottom swipe inside an app pulls the dock up.
    property bool dockDragging: false
    property real dockPeek: 0 // 0..1 while the finger is down
    property bool dockEditing: false // jiggle mode on the dock (long-press an icon)
    property bool dockPinned: false // stays after a short swipe, hides after 5 s or on any app change

    // Tablet: an app is in front -> the dock and the island slide away.
    readonly property bool appOpen: Mode.tablet && ToplevelManager.activeToplevel !== null
    // No app window focused (home screen / empty workspace).
    readonly property bool onHome: ToplevelManager.activeToplevel === null
    readonly property bool chromeShown: !appOpen || homeOpen || overviewOpen || overviewDragging
    readonly property bool dockShown: chromeShown || dockPinned || dockDragging || dockEditing || dockDragActive

    // Home and shade are mutually exclusive.
    function openHome() { settingsOpen = false; shadeOpen = false; overviewOpen = false; dockPinned = false; homeOpen = true; }
    function closeHome() { homeOpen = false; }
    function toggleHome() { if (homeOpen) closeHome(); else openHome(); }

    // Show the Halo desktop: close overlays and switch to the empty "home" workspace.
    function goHome() {
        dockPinned = false;
        homeOpen = false;
        shadeOpen = false;
        overviewOpen = false;
        settingsOpen = false;
        Quickshell.execDetached(["hyprctl", "eval", "go_home()"]);
    }

    function openSettings() { appInfoId = ""; homeOpen = false; shadeOpen = false; overviewOpen = false; dockPinned = false; settingsOpen = true; }
    function closeSettings() { settingsOpen = false; }
    property string settingsPage: "" // page to show on the next open (consumed by HaloSettings)
    function openSettingsPage(key) { settingsPage = key; openSettings(); }
    // Per-app info page (Settings > Apps > app). Set AFTER openSettings(): a plain open clears it.
    property string appInfoId: ""
    function openAppInfo(id) { openSettingsPage("apps"); appInfoId = id || ""; }
    function toggleSettings() { if (settingsOpen) closeSettings(); else openSettings(); }

    function openOverview() { settingsOpen = false; homeOpen = false; shadeOpen = false; dockPinned = false; overviewOpen = true; }
    function closeOverview() { overviewOpen = false; }
    function toggleOverview() { if (overviewOpen) closeOverview(); else openOverview(); }

    function openShade() {
        if (shadeOpen)
            return;
        settingsOpen = false;
        homeOpen = false;
        overviewOpen = false;
        shadeOpenedAt = Date.now();
        shadeOpen = true;
    }
    function closeShade() { shadeOpen = false; }
    // Backdrop taps: ignore the touch-up that finishes the opening swipe.
    function tapCloseShade() { if (Date.now() - shadeOpenedAt > 500) closeShade(); }
    function toggleShade() { if (shadeOpen) closeShade(); else openShade(); }

    // ---- iPad-style bottom-swipe helpers ---------------------------------------------------------
    function pinDock() {
        dockPinned = true;
        dockTimer.restart();
    }

    Timer {
        id: dockTimer
        interval: 5000
        onTriggered: if (!root.dockEditing) root.dockPinned = false
    }

    // Most recently used apps (newest first), for the swipe along the bottom edge.
    property var recent: []
    property var qsList: []
    property int qsIdx: 0
    property double qsAt: 0

    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            const t = ToplevelManager.activeToplevel;
            root.dockPinned = false;
            root.dockEditing = false;
            root.menuItem = null;
            root.winItem = null;
            if (t && root.stageItem)
                root.cancelSplitSelect(); // an app opened by other means: staging is over
            if (t)
                root.recent = [t].concat(root.recent.filter(x => x !== t));
        }
    }

    // dir +1 = swipe right = the app used before; -1 = swipe left = back towards the newer one.
    // The order is frozen for 2.5 s so repeated swipes walk the list instead of ping-ponging.
    function quickSwitch(dir) {
        const live = ToplevelManager.toplevels.values;
        const now = Date.now();
        if (now - qsAt > 2500) {
            const cur = ToplevelManager.activeToplevel;
            let list = recent.filter(t => live.indexOf(t) >= 0);
            if (cur)
                list = [cur].concat(list.filter(t => t !== cur));
            for (const t of live)
                if (list.indexOf(t) < 0)
                    list.push(t);
            qsList = list;
            qsIdx = 0;
        }
        qsAt = now;
        const n = Math.max(0, Math.min(qsList.length - 1, qsIdx + dir));
        if (n === qsIdx)
            return;
        qsIdx = n;
        qsList[n].activate();
    }

    // ---- dock -> screen drag (Split Screen) --------------------------------------------
    // Android: above the dock, the left half / right half of the screen are the two drop targets.
    function dockDragZoneAt(x, y) {
        if (y > dockRect.y - 24)
            return ""; // still over the dock: releasing here cancels
        return x < dockScreenW / 2 ? "split-left" : "split-right";
    }
    function beginDockDrag(item, screenName) {
        dockDragItem = item;
        dockDragIcon = item.icon;
        dockDragScreen = screenName;
        dockDragZone = "";
        dockDragActive = true;
    }
    function moveDockDrag(x, y) {
        dockDragX = x;
        dockDragY = y;
        dockDragZone = dockDragZoneAt(x, y);
    }
    function cancelDockDrag() {
        dockDragActive = false;
        dockDragItem = null;
        dockDragZone = "";
    }
    function finishDockDrag(screen) {
        const z = dockDragZone;
        const item = dockDragItem;
        cancelDockDrag();
        if (!item || z === "")
            return;
        const side = z.indexOf("left") >= 0 ? "left" : "right";
        Tiling.splitView(item, side, screen);
    }

    // ---- long-press app menu (Android TaskbarPopupController: split options + extras) ----------
    property var menuItem: null
    property string menuScreen: ""
    property real menuX: 0 // screen x of the icon centre
    property real menuY: 0 // screen y of the icon top
    function openAppMenu(item, cx, top, screenName) {
        menuX = cx;
        menuY = top;
        menuScreen = screenName;
        menuItem = item;
    }
    function closeAppMenu() { menuItem = null; }

    // ---- "Manage windows" carousel (Android ManageWindowsTaskbarShortcut) ------------------------
    property var winItem: null
    property string winScreen: ""
    property real winX: 0 // screen x of the icon centre
    property real winY: 0 // screen y of the icon top
    function openWindowsMenu(item, cx, top, screenName) {
        winX = cx;
        winY = top;
        winScreen = screenName;
        winItem = item;
    }
    function closeWindowsMenu() { winItem = null; }

    // ---- split select staging (Android SplitShortcut -> startSplitSelection) --------------------
    // With an app in front the menu item splits at once (Tiling.splitView). With nothing in front (home)
    // the chosen app is only STAGED: the next app opened (dock, home, library) becomes the other half.
    property var stageItem: null
    property string stageSide: ""
    property string stageScreenName: ""
    property var stageScreen: null
    property var stagePending: null
    readonly property bool splitStaging: stageItem !== null

    function splitFromMenu(item, side, screen) {
        closeAppMenu();
        const a = ToplevelManager.activeToplevel;
        if (a && item.windows.indexOf(a) < 0) {
            Tiling.splitView(item, side, screen);
            return;
        }
        stageSide = side;
        stageScreen = screen;
        stageScreenName = screen ? screen.name : "";
        stageItem = item;
    }
    function cancelSplitSelect() {
        stageItem = null;
        stageSide = "";
        stageScreen = null;
        stageScreenName = "";
    }
    // The second app was chosen: open it, wait until it is in front, then split the staged app in.
    function completeSplitSelect(second) {
        const item = stageItem;
        const side = stageSide;
        const scr = stageScreen || Quickshell.screens[0];
        cancelSplitSelect();
        if (!item)
            return;
        if (second.entry && item.entry && second.entry.id === item.entry.id) {
            Apps.activateNow(second); // same app picked: just open it
            return;
        }
        homeOpen = false;
        stagePending = { item: item, side: side, scr: scr };
        stageTimer.tries = 0;
        stageTimer.seen = false;
        stageTimer.restart();
        Apps.activateNow(second);
    }

    Timer {
        id: stageTimer
        property int tries: 0
        property bool seen: false
        interval: 250
        repeat: true
        onTriggered: {
            const p = root.stagePending;
            tries++;
            if (!p || tries > 40) {
                stop();
                root.stagePending = null;
                return;
            }
            const a = ToplevelManager.activeToplevel;
            if (a && p.item.windows.indexOf(a) < 0) {
                if (!seen) {
                    seen = true; // one more tick so the new window settles
                    return;
                }
                stop();
                root.stagePending = null;
                Tiling.splitView(p.item, p.side, p.scr);
            }
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void { root.toggleSettings(); }
        function open(): void { root.openSettings(); }
        function close(): void { root.closeSettings(); }
    }

    IpcHandler {
        target: "home"

        function toggle(): void { root.toggleHome(); }
        function open(): void { root.openHome(); }
        function close(): void { root.closeHome(); }
    }

    IpcHandler {
        target: "overview"

        function toggle(): void { root.toggleOverview(); }
        function open(): void { root.openOverview(); }
        function close(): void { root.closeOverview(); }
    }

    IpcHandler {
        target: "desktop"

        function show(): void { root.goHome(); }
    }

    IpcHandler {
        target: "shade"

        function toggle(): void { root.toggleShade(); }
        function open(): void { root.openShade(); }
        function close(): void { root.closeShade(); }
    }
}

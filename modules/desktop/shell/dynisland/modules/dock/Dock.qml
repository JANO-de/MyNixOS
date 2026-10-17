// =============================================================================
//  Dock — macOS-style floating dock at the bottom.
//  Items = pinned apps (Config.dock.pinned) + any other running apps.
//  Window is wide enough for the magnified size; input is masked to the dock
//  body so the empty area passes clicks through. `autoHide` slides it away.
//
//  Right-click menu = .desktop actions + open windows + the app's own TRAY menu
//  (SystemTray + QsMenuOpener) + pin/close. Drag a pinned icon to reorder.
//
//  TO CHANGE the pinned apps: Settings > Dock, or edit config.json.
// =============================================================================
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.SystemTray
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    visible: !(Sys.focusMode && Config.system.focusHide)   // Focus mode hides it
    required property var modelData
    screen: modelData
    readonly property var cfg: Config.dock
    // visibility: always | autohide | dodge (the old autoHide toggle still counts as autohide)
    readonly property string mode: cfg.behavior !== "always" ? cfg.behavior : (cfg.autoHide ? "autohide" : "always")
    readonly property bool dodging: mode === "dodge" && Niri.busy(win.screen ? win.screen.name : "")
    readonly property bool hideNow: (mode === "autohide" || dodging) && !hh.hovered && win.menuItem === null

    // ---- right-click menu state ----
    property var menuItem: null      // the dock item the menu belongs to (null = closed)
    property real menuX: 0           // icon center x (window coords)
    property string menuTitle: ""
    property var menuModel: []       // [{label, danger, run, header, indent, sep}]
    property var trayStack: []       // tray menu handles; last = the level being shown (submenus push)
    onMenuItemChanged: if (menuItem === null) trayStack = []

    // Lists the entries of the current tray (sub)menu. Empty when trayStack is empty.
    QsMenuOpener { id: trayOpener; menu: win.trayStack.length ? win.trayStack[win.trayStack.length - 1] : null }

    // media card (+ separator) width, animated in/out; shifts the icons left so everything stays centered
    readonly property bool showMedia: cfg.media && Media.player !== null
    property real mw: showMedia ? 272 : 0
    Behavior on mw { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    anchors { bottom: true }
    implicitWidth: Math.max(400, row.baseWidth + cfg.iconSize * 3 + 120 + 272)
    implicitHeight: cfg.iconSize * cfg.magnification + 70 + cfg.bottomMargin + 380   // extra room for the context menu (it scrolls beyond this)
    color: "transparent"
    exclusiveZone: cfg.reserveSpace && mode === "always" ? bg.height + cfg.bottomMargin * 2 : 0
    WlrLayershell.layer: win.menuItem ? WlrLayer.Overlay : WlrLayer.Top   // Overlay while the menu is open: stays above the click catcher
    WlrLayershell.namespace: "dynisland-dock"
    mask: Region { item: hit }

    // Full-screen invisible click catcher, alive only while the menu is open.
    // Sits on the Top layer (above app windows, below the Overlay dock), so a click anywhere else closes the menu.
    LazyLoader {
        active: win.menuItem !== null
        PanelWindow {
            screen: win.screen
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "dynisland-dock-dismiss"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: win.menuItem = null }
        }
    }

    // ---- model: pinned first, then running-but-unpinned ----------------------
    function norm(s) { return (s || "").toLowerCase().replace(/\.desktop$/, "") }
    function togglePin(appId) {
        const cur = Array.from(cfg.pinned);
        const i = cur.findIndex(x => norm(x) === norm(appId));
        if (i >= 0) cur.splice(i, 1); else cur.push(appId);
        cfg.pinned = cur;
    }
    function isPinned(appId) { return Array.from(cfg.pinned).some(x => norm(x) === norm(appId)) }
    // Reorder: move a pinned app to slot newIdx (among the visible pinned icons).
    function movePinned(appId, newIdx) {
        const vis = items.filter(o => o.pinned);
        const from = vis.findIndex(o => norm(o.appId) === norm(appId));
        if (from < 0) return;
        newIdx = Math.max(0, Math.min(vis.length - 1, newIdx));
        if (newIdx === from) return;
        const cur = Array.from(cfg.pinned);
        const ci = cur.findIndex(x => norm(x) === norm(appId));
        const target = cur.findIndex(x => norm(x) === norm(vis[newIdx].appId));
        if (ci < 0 || target < 0) return;
        const m = cur.splice(ci, 1)[0];
        cur.splice(target, 0, m);
        cfg.pinned = cur;
    }

    // Find the tray icon that belongs to a dock item (matches app id / name against tray id / title).
    function trayFor(item) {
        if (!cfg.trayMenus) return null;
        const keys = [item.appId, item.entry ? item.entry.name : "", item.entry ? item.entry.id : ""]
                     .map(norm).filter(k => k.length >= 3);
        for (const t of SystemTray.items.values) {
            const names = [t.id, t.title, t.tooltipTitle].map(norm).filter(n => n.length >= 3);
            for (const n of names) for (const k of keys)
                if (n === k || n.indexOf(k) >= 0 || k.indexOf(n) >= 0) return t;
        }
        return null;
    }

    function openMenu(item, cx) {
        const e = item.entry, ws = Niri.windowsFor(item.appId), m = [];
        m.push({ label: ws.length ? "New window" : "Open", run: () => { if (e) e.execute() } });
        // every action the app declares in its .desktop file (Actions=), minus a duplicate "New window"
        if (e && e.actions) for (const a of e.actions) {
            const n = (a.name || "").toLowerCase().replace(/\s+/g, " ");
            if (n === "new window") continue;
            m.push({ label: a.name, run: () => a.execute() });
        }
        // open windows: click one to focus it
        if (cfg.windowList && ws.length > 1) {
            m.push({ label: "Windows", header: true });
            ws.slice(0, 8).forEach(w => m.push({ label: w.title || item.appId, indent: true, run: () => Niri.focus(w.id) }));
            m.push({ sep: true });
        }
        m.push({ label: isPinned(item.appId) ? "Unpin from dock" : "Pin to dock", run: () => togglePin(item.appId) });
        if (ws.length) m.push({ label: ws.length > 1 ? "Close all windows (" + ws.length + ")" : "Close window", danger: true,
                                run: () => ws.forEach(w => Niri.close(w.id)) });
        // the app's own tray menu (mute, status, quit...), shown below
        const ti = trayFor(item);
        trayStack = ti && ti.hasMenu ? [ti.menu] : [];
        if (!ti && cfg.trayMenus)   // visible with `dynisland log`; use it to see what the tray ids are
            console.log("dock: no tray match for", item.appId, "| tray items:", SystemTray.items.values.map(t => t.id + "/" + t.title).join(", "));
        menuTitle = e ? e.name : item.appId; menuModel = m; menuX = cx; menuItem = item;
    }

    // Items = pinned apps (recognised ones) first, then running unpinned apps that have a desktop entry.
    readonly property var items: {
        const out = [];
        if (cfg.launcher) out.push({ key: "@launcher", appId: "@launcher", entry: null, pinned: false, launcher: true });
        for (const id of cfg.pinned) {
            const e = DesktopEntries.heuristicLookup(id);
            if (e && !out.some(o => norm(o.appId) === norm(id))) out.push({ key: id, appId: id, entry: e, pinned: true });
        }
        for (const w of Niri.windows) {
            const a = w.app_id;
            if (!a || out.some(o => norm(o.appId) === norm(a))) continue;
            const e = DesktopEntries.heuristicLookup(a);
            if (e) out.push({ key: a, appId: a, entry: e, pinned: false });
        }
        return out;
    }

    // Is the mouse near the dock? (used by autoHide)
    property bool near: false

    Item {
        id: root
        anchors.fill: parent

        // Mouse x relative to window center. HoverHandler is passive: clicks still reach the icons.
        HoverHandler { id: hh }
        readonly property real mouseX: hh.hovered ? hh.point.position.x - width / 2 + win.mw / 2 : -10000

        // hit area for the input mask (dock body, or a thin strip when hidden)
        Item {
            id: hit
            x: win.menuItem ? 0 : bg.x - 10
            width: win.menuItem ? parent.width : bg.width + 20
            height: win.menuItem ? parent.height
                  : (win.hideNow ? 6 : win.cfg.iconSize * win.cfg.magnification + 50 + win.cfg.bottomMargin)
            anchors.bottom: parent.bottom
        }

        // click anywhere else (while the menu is open) closes it
        MouseArea { anchors.fill: parent; enabled: win.menuItem !== null; acceptedButtons: Qt.AllButtons; onClicked: win.menuItem = null }

        Rectangle {   // soft drop shadow under the dock (follows bg, slides away with it)
            x: bg.x - 3; y: bg.y + 8; width: bg.width + 6; height: bg.height; radius: bg.radius + 2
            color: Glass.shadowColor; opacity: bg.hidden ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        Rectangle {
            id: bg
            readonly property bool hidden: win.hideNow
            anchors.horizontalCenter: parent.horizontalCenter
            y: hidden ? parent.height + 20 : parent.height - height - win.cfg.bottomMargin
            Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

            width: row.width + 28 + win.mw
            height: win.cfg.iconSize + 22
            radius: win.cfg.radius + Glass.radiusBoost
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, Config.appearance.glassOpacity)
            border.width: 1; border.color: Glass.outline

            Rectangle {   // glass sheen + inner highlight (shared look: see services/Glass.qml)
                anchors.fill: parent; radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0; color: Glass.sheenTop }
                    GradientStop { position: Glass.sheenStop; color: "transparent" }
                }
            }
            Rectangle { anchors { fill: parent; margins: 1 } radius: Math.max(0, parent.radius - 1)
                        color: "transparent"; border.width: 1; border.color: Glass.innerHighlight }

            Row {
                id: row
                spacing: 10
                anchors { horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -win.mw / 2; bottom: parent.bottom; bottomMargin: 11 }
                readonly property real baseWidth: win.items.length * (win.cfg.iconSize + spacing)
                Repeater {
                    model: win.items
                    DockIcon {
                        required property int index
                        required property var modelData   // must be declared: required props disable the implicit one
                        // nominal offset of this icon from the dock center (unmagnified layout)
                        slot: (index - (win.items.length - 1) / 2) * (win.cfg.iconSize + row.spacing)
                        mouseX: root.mouseX
                        item: modelData
                        onPinToggled: id => win.togglePin(id)
                        onMenuRequested: (it, cx) => win.openMenu(it, cx)
                        idx: index - (win.cfg.launcher ? 1 : 0)   // index among apps (launcher button excluded)
                        onReordered: (id, ni) => win.movePinned(id, ni)
                    }
                }
            }

            // separator + now-playing card, right of the icons
            Rectangle { visible: win.mw > 1; opacity: win.mw / 272; width: 1; height: win.cfg.iconSize * 0.6; color: "#44ffffff"
                        anchors { left: row.right; leftMargin: 10; verticalCenter: mediaCard.verticalCenter } }
            DockMedia {
                id: mediaCard
                visible: win.mw > 1; opacity: win.mw / 272
                height: win.cfg.iconSize
                anchors { left: row.right; leftMargin: 22; bottom: parent.bottom; bottomMargin: 11 }
            }
        }

        // ---- pin button: pinned = always visible; unpinned = auto-hide/dodge (hover the bottom edge still reveals it)
        IconButton {
            id: pinBtn
            readonly property bool pinned: win.mode === "always"
            icon: "keep"; active: pinned; diameter: 28; iconSize: 16
            z: 5
            anchors { right: bg.right; rightMargin: 8; bottom: bg.top; bottomMargin: 6 }
            opacity: hh.hovered ? 1 : 0
            enabled: opacity > 0.5
            Behavior on opacity { NumberAnimation { duration: 150 } }
            onClicked: {
                if (pinned) Config.dock.behavior = Config.dock.unpinMode === "dodge" ? "dodge" : "autohide";
                else { Config.dock.unpinMode = win.mode; Config.dock.behavior = "always" }
                Config.dock.autoHide = false;
            }
        }

        // ---- mini context menu ----
        Rectangle {
            id: menu
            visible: win.menuItem !== null; z: 10
            width: 240; height: Math.min(mcol.height + 16, Math.max(120, bg.y - 48)); radius: 14   // scrolls if taller
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.94)
            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.14)
            x: Math.max(8, Math.min(root.width - width - 8, win.menuX - width / 2))
            y: Math.max(4, bg.y - height - 40)

            Flickable {
              anchors { fill: parent; margins: 8 }
              contentHeight: mcol.height; clip: true; boundsBehavior: Flickable.StopAtBounds
            Column {
                id: mcol
                width: parent.width; spacing: 2
                Text {
                    width: parent.width; height: 24; leftPadding: 8; elide: Text.ElideRight
                    text: win.menuTitle; color: Theme.surfaceFg; opacity: 0.6
                    font.pixelSize: 12; font.bold: true; verticalAlignment: Text.AlignVCenter
                }
                Repeater {
                    model: win.menuModel
                    Rectangle {
                        required property var modelData    // declared: required props disable the implicit one
                        readonly property bool plain: !modelData.header && !modelData.sep
                        width: mcol.width; radius: 8
                        height: modelData.sep ? 9 : (modelData.header ? 22 : 30)
                        color: plain && mma.containsMouse ? "#2affffff" : "transparent"
                        Rectangle { visible: modelData.sep === true; anchors.centerIn: parent; width: parent.width - 16; height: 1; color: "#33ffffff" }
                        Text {
                            visible: !modelData.sep
                            anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right
                                      leftMargin: modelData.indent ? 18 : 8; rightMargin: 8 }
                            elide: Text.ElideRight
                            text: modelData.label || ""
                            font.pixelSize: modelData.header ? 11 : 13; font.bold: modelData.header === true
                            opacity: modelData.header ? 0.55 : 1
                            color: modelData.danger ? "#ff7b7b" : Theme.surfaceFg
                        }
                        MouseArea {
                            id: mma; anchors.fill: parent; hoverEnabled: true; enabled: parent.plain
                            onClicked: { const r = modelData.run; win.menuItem = null; r() }
                        }
                    }
                }

                // ---- the app's tray menu (only when the app has a tray icon)
                Rectangle {   // separator + title
                    visible: trayOpener.children && trayOpener.children.values.length > 0
                    width: mcol.width; height: 24; color: "transparent"
                    Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 8; rightMargin: 8 } height: 1; color: "#33ffffff" }
                    Text { anchors { left: parent.left; leftMargin: 8; bottom: parent.bottom }
                           text: "App menu"; color: Theme.surfaceFg; opacity: 0.55; font.pixelSize: 11; font.bold: true }
                }
                Rectangle {   // back (inside a submenu)
                    visible: win.trayStack.length > 1
                    width: mcol.width; height: 30; radius: 8
                    color: backMa.containsMouse ? "#2affffff" : "transparent"
                    Row { anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 6 } spacing: 4
                          Icon { name: "chevron_left"; size: 18; color: Theme.surfaceFg }
                          Text { text: "Back"; color: Theme.surfaceFg; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter } }
                    MouseArea { id: backMa; anchors.fill: parent; hoverEnabled: true
                                onClicked: win.trayStack = win.trayStack.slice(0, -1) }
                }
                Repeater {
                    model: trayOpener.children    // QsMenuEntry: text, isSeparator, enabled, hasChildren, buttonType, checkState, triggered()
                    Rectangle {
                        required property var modelData
                        readonly property bool sep: modelData.isSeparator
                        width: mcol.width; radius: 8; height: sep ? 9 : 30
                        color: !sep && modelData.enabled && tma.containsMouse ? "#2affffff" : "transparent"
                        Rectangle { visible: parent.sep; anchors.centerIn: parent; width: parent.width - 16; height: 1; color: "#33ffffff" }
                        Icon {   // check / radio mark
                            visible: !parent.sep && modelData.buttonType !== 0 && modelData.checkState === Qt.Checked
                            name: "check"; size: 16; color: Theme.primary
                            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 6 }
                        }
                        Text {
                            visible: !parent.sep
                            anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: 26; rightMargin: modelData.hasChildren ? 26 : 8 }
                            elide: Text.ElideRight; font.pixelSize: 13
                            text: (modelData.text || "").replace(/_/g, "")   // strip GTK mnemonics
                            color: Theme.surfaceFg; opacity: modelData.enabled ? 1 : 0.4
                        }
                        Icon {   // submenu arrow
                            visible: !parent.sep && modelData.hasChildren
                            name: "chevron_right"; size: 18; color: Theme.surfaceFg
                            anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 6 }
                        }
                        MouseArea {
                            id: tma; anchors.fill: parent; hoverEnabled: true; enabled: !parent.sep && modelData.enabled
                            onClicked: {
                                if (modelData.hasChildren) win.trayStack = win.trayStack.concat([modelData]);
                                else { modelData.triggered(); win.menuItem = null }
                            }
                        }
                    }
                }
            }
            }
        }
    }
}

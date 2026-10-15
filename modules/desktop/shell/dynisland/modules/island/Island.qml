// =============================================================================
//  Island — the Dynamic Island. A black pill at the top of the screen that
//  morphs (animated width/height/radius) between modes:
//
//    idle  : time + date/weather (or album art + mini equalizer when playing)
//    osd   : volume/brightness bar
//    notif : notification banner
//    full  : (hover) media + clock/weather + quick controls
//    tray  : an app's tray menu (opened from the tray strip), drawn inside the pill
//    panel : clock/weather/calendar/wifi/bluetooth/audio/power/history (UiState.openPanel)
//
//  Priority: tray > panel > notif > full > osd > idle  (a banner stays put while you hover it, so its buttons are clickable).
//  Input is limited to the pill via `mask`, so the transparent rest of the
//  window never blocks clicks.
//
//  TO ADD A MODE: add a view file, a size in `sizes`, a branch in `mode`,
//  and instantiate the view below with `active: win.mode === "name"`.
// =============================================================================
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property var cfg: Config.island

    anchors { top: true }                       // top only => centered horizontally
    implicitWidth: cfg.fullWidth + 160          // room for glow + overshoot
    implicitHeight: Math.max(cfg.fullHeight, 520) + cfg.topMargin + 90   // tall enough for the tray menu / panels
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dynisland"
    WlrLayershell.keyboardFocus: UiState.panelKeys ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None   // typing in a panel (Wi-Fi password)
    mask: Region { item: pill }

    // ---- state -----------------------------------------------------------
    property bool hovered: false                // debounced hover (or click-toggled)
    readonly property bool full: hovered || UiState.islandPinned
    readonly property bool trayOpen: UiState.trayStack.length > 0
    readonly property bool panelOpen: UiState.panel !== ""
    readonly property string mode: trayOpen ? "tray" : panelOpen ? "panel" : Notifs.current ? "notif" : full ? "full" : Osd.active ? "osd" : "idle"
    // visibility: always | autohide | dodge. Only the idle pill hides; banners, OSD, panels and hover always show.
    readonly property bool dodging: cfg.behavior === "dodge" && Niri.busy(win.screen ? win.screen.name : "")
    readonly property bool hideNow: (cfg.behavior === "autohide" || dodging) && mode === "idle" && !hovered && !ph.hovered
    onHoveredChanged: Notifs.hold = hovered      // hovering a banner pauses its auto-hide
    onFullChanged: Sys.watching = full          // poll wifi/brightness only while open

    readonly property var sizes: ({
        idle:  [cfg.idleWidth + (Media.playing ? 60 : 0), cfg.idleHeight],
        osd:   [330, 54],
        notif: [430, (Notifs.current && Notifs.current.actions && Notifs.current.actions.length > 0) ? 128 : 88],
        full:  [cfg.fullWidth, cfg.fullHeight],
        tray:  [320, UiState.trayHeight],
        panel: panelSizes[UiState.panel] || [380, 300]
    })
    readonly property var panelSizes: ({
        clock: [400, 330], weather: [460, 360], calendar: [480, 450], wifi: [400, 440],
        bluetooth: [400, 420], audio: [420, 400], power: [480, Server.active ? 215 : 170], history: [440, 470]
    })

    // Click anywhere outside the island closes the tray menu (full-screen invisible catcher, alive only while open).
    LazyLoader {
        active: win.trayOpen || win.panelOpen
        PanelWindow {
            screen: win.screen
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Top               // above apps, below the Overlay island
            WlrLayershell.namespace: "dynisland-tray-dismiss"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: { UiState.trayStack = []; UiState.closePanel() } }
        }
    }

    Timer { id: openT;  interval: cfg.hoverDelay; onTriggered: win.hovered = true }
    Timer { id: closeT; interval: cfg.closeDelay; onTriggered: win.hovered = false }  // hover guard

    Rectangle {
        id: pill
        x: (win.width - width) / 2
        y: win.hideNow ? 4 - height : cfg.topMargin     // hidden = only a 4 px sliver stays (hover it to reveal)
        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        width: win.sizes[win.mode][0]
        height: win.sizes[win.mode][1]
        radius: Math.min(height / 2, cfg.fullRadius)
        color: "black"
        // "pulse" cava style: the whole island breathes with the bass
        scale: Config.cava.style === "pulse" ? 1 + Math.min(1, Cava.level * Config.cava.sensitivity) * 0.05 : 1
        Behavior on scale { NumberAnimation { duration: 60 } }

        // Spring-ish morph, like iOS
        Behavior on width  { NumberAnimation { duration: cfg.animMs; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on height { NumberAnimation { duration: cfg.animMs; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }

        HoverHandler { id: ph }   // always on: reveals a hidden island
        HoverHandler {
            enabled: cfg.expandOnHover
            onHoveredChanged: {
                if (hovered) { closeT.stop(); openT.restart() }
                else { openT.stop(); closeT.restart() }
            }
        }
        TapHandler { enabled: !cfg.expandOnHover; onTapped: win.hovered = !win.hovered }

        // behind the pill
        GlowRing { z: -1 }
        // inside the pill (behind content)
        Visualizer {}

        IdleView  { active: win.mode === "idle" }
        OsdView   { active: win.mode === "osd" }
        NotifView { active: win.mode === "notif" }
        FullView  { active: win.mode === "full" }
        TrayMenuView { active: win.mode === "tray" }
        PanelView { active: win.mode === "panel" }
    }
}

// =============================================================================
//  Island — the Dynamic Island. A black pill at the top of the screen that
//  morphs (animated width/height/radius) between modes:
//
//    idle  : time + date/weather (or album art + mini equalizer when playing)
//    osd   : volume/brightness bar
//    notif : notification banner
//    full  : (hover) media + clock/weather + quick controls
//
//  Priority: full > notif > osd > idle.
//  Input is limited to the pill via `mask`, so the transparent rest of the
//  window never blocks clicks.
//
//  TO ADD A MODE: add a view file, a size in `sizes`, a branch in `mode`,
//  and instantiate the view below with `active: win.mode === "name"`.
// =============================================================================
import QtQuick
import Quickshell
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
    implicitHeight: cfg.fullHeight + cfg.topMargin + 90
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dynisland"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: pill }

    // ---- state -----------------------------------------------------------
    property bool hovered: false                // debounced hover (or click-toggled)
    readonly property bool full: hovered || UiState.islandPinned
    readonly property string mode: full ? "full" : Notifs.current ? "notif" : Osd.active ? "osd" : "idle"
    onFullChanged: Sys.watching = full          // poll wifi/brightness only while open

    readonly property var sizes: ({
        idle:  [cfg.idleWidth + (Media.playing ? 60 : 0), cfg.idleHeight],
        osd:   [330, 54],
        notif: [430, 88],
        full:  [cfg.fullWidth, cfg.fullHeight]
    })

    Timer { id: openT;  interval: cfg.hoverDelay; onTriggered: win.hovered = true }
    Timer { id: closeT; interval: cfg.closeDelay; onTriggered: win.hovered = false }  // hover guard

    Rectangle {
        id: pill
        x: (win.width - width) / 2
        y: cfg.topMargin
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
    }
}

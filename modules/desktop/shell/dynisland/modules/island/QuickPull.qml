// Quick-settings blob: grows out of the island's right side. Open it by hovering the spot
// right of the island, or with the keybind (`dynisland ipc quick toggle`, stays open until
// toggled again or you click outside). Hover-opened: closes when the cursor leaves.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: win
    readonly property var cfg: Config.island
    readonly property bool open: UiState.quickOpen && Config.system.quickPull
    readonly property real px: width / 2 + UiState.pillW / 2        // island's right edge
    readonly property real topY: cfg.topMargin
    readonly property real blobW: 300
    readonly property real blobH: 270

    visible: Config.system.quickPull
    anchors { top: true; left: true; right: true }
    implicitHeight: topY + blobH + 40
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dynisland-quick"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    onOpenChanged: Sys.watching = open

    // input: hover strip + blob; while key-pinned the whole window (click outside closes)
    mask: Region {
        item: UiState.quickPinned ? catcher : zone
        Region { item: blob }
    }

    MouseArea {
        id: catcher; anchors.fill: parent; enabled: UiState.quickPinned
        onClicked: { UiState.quickPinned = false; UiState.quickOpen = false }
    }

    // hover strip beside the island (also bridges the gap to the open blob)
    Item {
        id: zone
        x: win.px; y: win.topY
        width: 46; height: win.open ? win.blobH : Math.max(36, cfg.idleHeight)
        HoverHandler { id: zh }
    }

    readonly property bool over: zh.hovered || bh.hovered
    onOverChanged: {
        if (over) { closeT.stop(); if (!open) openT.restart() }
        else { openT.stop(); if (open && !UiState.quickPinned) closeT.restart() }
    }
    Timer { id: openT;  interval: 120; onTriggered: UiState.quickOpen = true }
    Timer { id: closeT; interval: 380; onTriggered: if (!UiState.quickPinned) UiState.quickOpen = false }

    Rectangle {
        id: blob
        x: win.px + 8; y: win.topY
        width: win.open ? win.blobW : 0
        height: win.open ? win.blobH : 0
        visible: width > 2
        radius: Math.min(height / 2, 30)
        color: "black"; border.width: 1; border.color: Glass.outline
        clip: true
        Behavior on width  { NumberAnimation { duration: cfg.animMs; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on height { NumberAnimation { duration: cfg.animMs; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        HoverHandler { id: bh }
        Loader {
            active: win.open
            anchors { fill: parent; margins: 18 }
            opacity: blob.width > win.blobW * 0.85 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
            sourceComponent: ControlsCard { inPull: true }
        }
    }
}

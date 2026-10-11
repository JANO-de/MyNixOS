// =============================================================================
//  DynIsland — entry point.  Run with:  qs -c dynisland
//
//  Layout (import path "qs.<folder>"):
//    config/      Config.qml        persisted settings (~/.config/dynisland/config.json)
//    services/    singletons: Theme (matugen), Cava, Media, Notifs, Osd,
//                 Sys (wifi/bt/brightness), Niri (windows), Weather, Clock, UiState
//    components/  reusable UI bits (Icon, IconButton, ValueSlider, Toggle, ...)
//    modules/     island/ dock/ settings/ background/ widgets/
//
//  TO ADD A MODULE: create modules/<name>/Foo.qml (a PanelWindow with
//  `required property var modelData`), import it below, add a Variants line.
// =============================================================================
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.modules.background
import qs.modules.island
import qs.modules.dock
import qs.modules.widgets
import qs.modules.settings

ShellRoot {
    // One instance per monitor.
    Variants { model: Quickshell.screens; Wallpaper {} }
    Variants { model: Config.island.enabled ? Quickshell.screens : []; Island {} }
    Variants { model: Config.dock.enabled ? Quickshell.screens : []; Dock {} }
    Variants { model: Quickshell.screens; DesktopWidgets {} }

    Settings {}   // single centered overlay, toggled via UiState.settingsOpen

    // ---- IPC (bind in niri config.kdl, e.g. spawn "qs" "-c" "dynisland" "ipc" "call" "settings" "toggle")
    IpcHandler { target: "settings"; function toggle(): void { UiState.settingsOpen = !UiState.settingsOpen } }
    IpcHandler { target: "island";   function toggle(): void { UiState.islandPinned = !UiState.islandPinned } }
    IpcHandler { target: "osd";      function show(kind: string, value: real): void { Osd.show(kind, value) } }
}

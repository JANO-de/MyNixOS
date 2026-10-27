//@ pragma UseQApplication
// =============================================================================
//  DynIsland — entry point.  Run with:  qs -c dynisland
//
//  Layout (import path "qs.<folder>"):
//    config/      Config.qml        persisted settings (~/.config/dynisland/config.json)
//    services/    singletons: Theme (matugen), Cava, Media, Notifs, Osd,
//                 Sys (wifi/bt/brightness), Wm (windows, compositor-agnostic), Weather, Clock, UiState
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
import qs.modules.lock
import qs.modules.launcher
import qs.modules.spotlight
import qs.modules.ai

ShellRoot {
    Component.onCompleted: { Usb.ready; Updates.ready; Clip.items } //  // instantiate so the clipboard watcher starts at login
    // One instance per monitor.
    Variants { model: Quickshell.screens; Wallpaper {} }
    Variants { model: Config.island.enabled ? Quickshell.screens : []; Island {} }
    Variants { model: Config.dock.enabled && !Server.active ? Quickshell.screens : []; Dock {} }   // off in server mode
    Variants { model: Server.active ? [] : Quickshell.screens; DesktopWidgets {} }   // off in server mode

    Variants { model: Quickshell.screens; DesktopMenu {} }   // right-click menu on the desktop

    LauncherDrawer {}   // app drawer (UiState.launcherOpen)
    Spotlight {}        // centered search bar, macOS Alt+Space style (UiState.spotlightOpen)
    AIChat {}           // AI chat panel (UiState.aiOpen)
    Lock {}       // session lock screen (UiState.locked)

    Settings {}   // single centered overlay, toggled via UiState.settingsOpen


    // ---- IPC (bind in niri config.kdl, e.g. spawn "qs" "-c" "dynisland" "ipc" "call" "settings" "toggle")
    IpcHandler { target: "settings"; function toggle(): void { UiState.settingsOpen = !UiState.settingsOpen } }
    IpcHandler { target: "quick";    function toggle(): void { const on = UiState.islandPinned && UiState.quickPage; UiState.islandPinned = !on; UiState.quickPage = !on } }
    IpcHandler { target: "tools"
        function emoji(): void { UiState.openPanel("emoji") }
        function clipboard(): void { UiState.openPanel("clipboard") }
        function color(): void { Sys.pickColor() }
        function note(): void { UiState.openPanel("note") }
    }
    IpcHandler { target: "island";   function toggle(): void { UiState.islandPinned = !UiState.islandPinned } }
    IpcHandler { target: "spotlight"
        function toggle(): void { UiState.spotlightOpen = !UiState.spotlightOpen }
        function open(): void { UiState.spotlightOpen = true }
        function close(): void { UiState.spotlightOpen = false }
    }
    IpcHandler { target: "ai"
        function toggle(): void { UiState.aiOpen = !UiState.aiOpen }
        function open(): void { UiState.aiOpen = true }
        function close(): void { UiState.aiOpen = false }
        function ask(text: string): void { UiState.aiOpen = true; AI.send(text) }   // e.g. bind: ipc call ai ask "summarize my clipboard"
        function newchat(): void { AI.newSession(); UiState.aiOpen = true }
    }
    IpcHandler { target: "launcher"
        function toggle(): void { UiState.launcherOpen = !UiState.launcherOpen }
        function open(): void { UiState.launcherOpen = true }
        function close(): void { UiState.launcherOpen = false }
    }
    IpcHandler { target: "lock"
        function lock(): void { UiState.locked = true }
        function unlock(): void { if (Config.system.lockIpcUnlock) UiState.locked = false }   // emergency only
    }
    IpcHandler { target: "server"
        function toggle(): void { Server.toggle() }
        function enable(): void { Server.enable() }
        function disable(): void { Server.disable() }
    }
    IpcHandler { target: "osd";      function show(kind: string, value: real): void { Osd.show(kind, value) } }
    IpcHandler { target: "activity"
        function push(id: string, label: string, icon: string, progress: real, color: string, ttl: real): void { Activities.push(id, label, icon, progress, color, ttl) }
        function clear(id: string): void { Activities.clear(id) }
        function clearAll(): void { Activities.clearAll() }
    }
}

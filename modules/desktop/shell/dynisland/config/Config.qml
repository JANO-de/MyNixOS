// =============================================================================
//  Config — all settings, persisted to ~/.config/dynisland/config.json
//  (hot-reloaded if edited by hand). Changes apply LIVE; they are written to disk
//  immediately, EXCEPT while Settings is open (`hold`): then they wait for Save, and
//  Discard reverts to the file.
//
//  TO ADD A SETTING: add `property <type> name: default` in the right
//  JsonObject below, then read it anywhere as Config.<group>.<name>.
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.config/dynisland"
    property bool ready: false   // true once the config dir exists
    property bool hold: false    // Settings open: don't write to disk until save()
    property bool dirty: false   // live changes not yet written
    property bool discarding: false
    function save() { fv.writeAdapter(); dirty = false }

    // Discard = read the saved file ourselves and put every saved value back (FileView.reload()
    // alone did not reliably overwrite values changed in QML). While discarding, nothing is written.
    function discard() { discarding = true; dirty = false; reader.running = true }
    function applySaved(text) {
        try {
            const j = JSON.parse(text);
            for (const sec of ["appearance", "island", "cava", "dock", "widgets", "lock", "system", "calendar"]) {
                if (!j[sec]) continue;
                for (const k in j[sec]) root[sec][k] = j[sec][k];
            }
        } catch (e) { console.warn("Config: discard could not read the saved file:", e) }
        clearT.restart();
    }
    Process {
        id: reader
        command: ["cat", root.dir + "/config.json"]
        stdout: StdioCollector { onStreamFinished: root.applySaved(text) }
        onExited: code => { if (code !== 0) root.discarding = false }
    }
    // the reverted values re-emit adapterUpdated; clear the flags after they settle
    Timer { id: clearT; interval: 300; onTriggered: { root.dirty = false; root.discarding = false } }

    property alias appearance: adapter.appearance
    property alias island: adapter.island
    property alias cava: adapter.cava
    property alias dock: adapter.dock
    property alias widgets: adapter.widgets
    property alias lock: adapter.lock
    property alias system: adapter.system
    property alias calendar: adapter.calendar

    // Positions is a plain object: reassign it whole so change signals fire.
    function setWidgetPos(id, x, y) {
        const p = Object.assign({}, widgets.positions);
        p[id] = { x: x, y: y };
        widgets.positions = p;
    }

    // Lock card position (center, as fraction of the screen so it fits any monitor).
    function setLockPos(id, fx, fy) {
        const p = Object.assign({}, lock.positions);
        p[id] = { x: fx, y: fy };
        lock.positions = p;
    }

    Process { running: true; command: ["mkdir", "-p", root.dir]; onExited: root.ready = true }

    FileView {
        id: fv
        path: root.ready ? root.dir + "/config.json" : ""
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: { if (root.discarding) return; if (root.hold) root.dirty = true; else writeAdapter() }
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }

        adapter: JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property string wallpaper: ""
                property string wallpaperDir: root.home + "/Pictures/Wallpapers"
                property bool darkMode: true
                // scheme-tonal-spot | scheme-vibrant | scheme-expressive | scheme-fruit-salad
                // | scheme-rainbow | scheme-content | scheme-monochrome
                property string scheme: "scheme-tonal-spot"
                property string font: "Inter"
                property string accentOverride: ""    // "" = from wallpaper, or "#rrggbb"
                property real glassOpacity: 0.6        // dock + widget cards (0.2..1)
                property string wallpaperFill: "crop"  // crop | fit | stretch
                property real wallpaperDim: 0          // 0..0.8 black overlay
            }

            property JsonObject island: JsonObject {
                property bool enabled: true
                property bool expandOnHover: true     // false = click to expand
                property int hoverDelay: 60           // ms before expanding
                property int closeDelay: 350          // ms hover guard before collapsing
                property int topMargin: 8
                property int idleWidth: 250
                property int idleHeight: 38
                property int fullWidth: 700
                property int fullHeight: 210
                property int fullRadius: 34
                property int animMs: 420              // morph animation length
                property bool use24h: true
                property bool showWeather: true
                property string location: ""          // "" = auto by IP, or "Algeciras"
                property string units: "m"            // m metric, u US
                property real notifSeconds: 5          // banner time when the app sets none
            }

            property JsonObject cava: JsonObject {
                property bool enabled: true
                property string style: "glow"         // glow | bars | wave | pulse | none
                property bool rainbow: false          // cycle hue instead of theme accent
                property real sensitivity: 1.4
                property real glowStrength: 1.0
            }

            property JsonObject dock: JsonObject {
                property bool enabled: true
                property bool launcher: true          // first dock icon: opens the app drawer
                property bool autoHide: false
                property bool reserveSpace: false     // push windows up (exclusive zone)
                property bool trayMenus: true         // right-click menu also lists the app's tray menu
                property bool windowList: true        // right-click menu lists open windows
                property int radius: 24               // dock corner radius
                property bool showRunning: true       // dots under running apps
                property int iconSize: 52
                property real magnification: 1.7
                property int bottomMargin: 10
                // desktop-entry ids/names, resolved with DesktopEntries.heuristicLookup
                property var pinned: ["Alacritty", "zen", "vesktop", "org.gnome.Nautilus"]
            }

            property JsonObject widgets: JsonObject {
                property bool clock: true
                property bool weather: true
                property bool media: true
                property bool system: true            // CPU / RAM / disk
                property int cardRadius: 28
                property bool calendar: true
                property var positions: ({})          // { id: {x, y} }
            }

            // cards shown on the lock screen (Settings > Desktop widgets)
            property JsonObject lock: JsonObject {
                property bool media: true             // only visible while a player exists
                property bool weather: true
                property bool calendar: true          // next events
                property var positions: ({})          // { id: {x, y} } card CENTER as 0..1 fractions of the screen
            }

            property JsonObject system: JsonObject {
                property string terminal: "alacritty"     // used by the launcher's "> command"
                property bool builtinLock: true          // use the shell's own lock screen
                property string pamService: "login"      // file in /etc/pam.d used to check the password
                property bool lockIpcUnlock: true        // allow `ipc call lock unlock` (emergency; turn off when stable)
                property string lockCmd: "swaylock -f"   // used only if builtinLock is off
                property string logoutCmd: "niri msg action quit --skip-confirmation"
                property string rebootCmd: "systemctl reboot"
                property string shutdownCmd: "systemctl poweroff"
                property string suspendCmd: "systemctl suspend"
            }

            property JsonObject calendar: JsonObject {
                property bool enabled: true
                property int syncMinutes: 15
                property bool vdirsyncer: false       // run `vdirsyncer sync` before reading folder sources (CalDAV)
                property bool mondayFirst: true
                property var sources: []              // [{ name, kind: "url"|"folder", value, color }]
            }
        }
    }
}

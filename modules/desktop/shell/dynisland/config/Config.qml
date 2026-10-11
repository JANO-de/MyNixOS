// =============================================================================
//  Config — all settings, persisted to ~/.config/dynisland/config.json
//  (hot-reloaded if edited by hand, auto-saved when changed from the UI).
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

    property alias appearance: adapter.appearance
    property alias island: adapter.island
    property alias cava: adapter.cava
    property alias dock: adapter.dock
    property alias widgets: adapter.widgets
    property alias system: adapter.system

    // Positions is a plain object: reassign it whole so change signals fire.
    function setWidgetPos(id, x, y) {
        const p = Object.assign({}, widgets.positions);
        p[id] = { x: x, y: y };
        widgets.positions = p;
    }

    Process { running: true; command: ["mkdir", "-p", root.dir]; onExited: root.ready = true }

    FileView {
        path: root.ready ? root.dir + "/config.json" : ""
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
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
                property bool autoHide: false
                property bool reserveSpace: false     // push windows up (exclusive zone)
                property int iconSize: 52
                property real magnification: 1.7
                property int bottomMargin: 10
                // desktop-entry ids/names, resolved with DesktopEntries.heuristicLookup
                property var pinned: ["firefox", "kitty", "org.gnome.Nautilus", "discord", "spotify"]
            }

            property JsonObject widgets: JsonObject {
                property bool clock: true
                property bool weather: true
                property bool media: true
                property var positions: ({})          // { id: {x, y} }
            }

            property JsonObject system: JsonObject {
                property string lockCmd: "swaylock -f"
                property string logoutCmd: "niri msg action quit --skip-confirmation"
                property string rebootCmd: "systemctl reboot"
                property string shutdownCmd: "systemctl poweroff"
            }
        }
    }
}

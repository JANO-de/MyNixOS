pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Colours for standalone Halo apps: read from the shell's cache (~/.config/halo/theme.json), same roles as services/Theme.qml.
Singleton {
    id: root
    property color accent: "#a6c8ff"
    property color accentInk: "#0b1b33"
    property color bg: "#111a1b"
    property color card: "#1c3032"
    property color cardHigh: "#2a4547"
    property color text: "#ffffff"
    property color dim: "#8e8e93"
    readonly property color line: Qt.rgba(1, 1, 1, 0.12)
    readonly property string home: Quickshell.env("HOME")

    function apply(c) {
        if (c.primary)
            accent = c.primary;
        if (c.on_primary)
            accentInk = c.on_primary;
        if (c.surface)
            bg = c.surface;
        if (c.surface_container_high)
            card = c.surface_container_high;
        if (c.surface_container_highest)
            cardHigh = c.surface_container_highest;
        if (c.on_surface_variant)
            dim = c.on_surface_variant;
    }

    FileView {
        path: root.home + "/.config/halo/theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.apply(JSON.parse(text()));
            } catch (e) {}
        }
    }
}

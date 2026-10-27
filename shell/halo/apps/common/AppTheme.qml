pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Colours for standalone Halo apps: read from the shell's cache (~/.config/halo/theme.json), same roles as services/Theme.qml.
// Light/dark follows ~/.config/halo/scheme.json (written by the shell); line/hover/low flip with it, like Theme.tint().
Singleton {
    id: root
    property bool light: false
    property color accent: "#a6c8ff"
    property color accentInk: "#0b1b33"
    property color bg: "#111a1b"
    property color card: "#1c3032"
    property color cardHigh: "#2a4547"
    property color text: "#ffffff"
    property color dim: "#8e8e93"
    readonly property color line: light ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.12)
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, 0.24)
    readonly property color low: Qt.tint(bg, light ? Qt.rgba(0, 0, 0, 0.04) : Qt.rgba(1, 1, 1, 0.04))
    readonly property color hover: light ? Qt.rgba(0, 0, 0, 0.07) : Qt.rgba(1, 1, 1, 0.07)
    readonly property color danger: light ? "#c5221f" : "#ff8a80"
    readonly property string home: Quickshell.env("HOME")

    // White overlay on dark, black overlay on light (same as Theme.tint in the shell).
    function tint(a) {
        return light ? Qt.rgba(0, 0, 0, a) : Qt.rgba(1, 1, 1, a);
    }

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
        if (c.on_surface)
            text = c.on_surface;
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

    FileView {
        path: root.home + "/.config/halo/scheme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.light = JSON.parse(text()).light === true;
            } catch (e) {}
        }
    }
}

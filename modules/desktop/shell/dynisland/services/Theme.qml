// =============================================================================
//  Theme — Material-You colors generated from the wallpaper with `matugen`.
//  Re-runs when wallpaper / dark mode / scheme change. Defaults are used until
//  matugen succeeds.
//
//  USE: color: Theme.primary.   TO ADD A COLOR: add a property + a set() line.
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property color primary: "#a8c7fa"
    property color onPrimary: "#062e6f"
    property color secondary: "#bec6dc"
    property color tertiary: "#dabde2"
    property color surface: "#111318"
    property color surfaceContainer: "#1d2024"
    property color surfaceContainerHigh: "#282a2f"
    property color onSurface: "#e2e2e9"
    property color onSurfaceVariant: "#c4c6d0"
    property color outline: "#8e9099"

    Behavior on primary { ColorAnimation { duration: 400 } }
    Behavior on surface { ColorAnimation { duration: 400 } }

    readonly property string wp: Config.appearance.wallpaper
    readonly property bool dark: Config.appearance.darkMode
    readonly property string scheme: Config.appearance.scheme
    onWpChanged: regen()
    onDarkChanged: regen()
    onSchemeChanged: regen()

    function regen() { if (wp !== "") { gen.running = false; gen.running = true } }

    Process {
        id: gen
        command: ["matugen", "image", root.wp, "--json", "hex", "--dry-run",
                  "-m", root.dark ? "dark" : "light", "-t", root.scheme]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    function parse(text) {
        try {
            const j = JSON.parse(text);
            const c = (j.colors && (j.colors[dark ? "dark" : "light"] || j.colors)) || j;
            // v2 gives "#hex"; v3 may nest as {color: "#hex"}
            const v = k => (typeof c[k] === "string" ? c[k] : (c[k] ? c[k].color : undefined));
            const set = (prop, key) => { const x = v(key); if (x) root[prop] = x; };
            set("primary", "primary");     set("onPrimary", "on_primary");
            set("secondary", "secondary"); set("tertiary", "tertiary");
            set("surface", "surface");     set("surfaceContainer", "surface_container");
            set("surfaceContainerHigh", "surface_container_high");
            set("onSurface", "on_surface"); set("onSurfaceVariant", "on_surface_variant");
            set("outline", "outline");
        } catch (e) { console.warn("Theme: matugen parse failed", e) }
    }

    Component.onCompleted: regen()
}

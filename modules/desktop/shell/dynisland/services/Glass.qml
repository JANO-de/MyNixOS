// =============================================================================
//  Glass — single source of truth for the "glassy" look shared by the dock,
//  the island pill and the settings window. Change Config.appearance.glassPreset
//  (or the glass* sliders, under "custom") and every surface updates together.
//  Pick a preset from code too: write it straight into
//  ~/.config/dynisland/config.json -> appearance.glassPreset.
// =============================================================================
pragma Singleton
import QtQuick
import qs.config

QtObject {
    id: root

    // name -> { outline, sheen, shadow, tint, radiusBoost }
    readonly property var presets: ({
        default: { outline: 0.20, sheen: 0.11, shadow: 0.25, tint: 0.0, radiusBoost: 0 },
        ios:     { outline: 0.30, sheen: 0.16, shadow: 0.35, tint: 0.0, radiusBoost: 10 },   // iOS 26-ish: rounder, brighter sheen
        minimal: { outline: 0.10, sheen: 0.0,  shadow: 0.12, tint: 0.0, radiusBoost: 0 },     // flat, near-invisible chrome
        vibrant: { outline: 0.25, sheen: 0.14, shadow: 0.30, tint: 0.45, radiusBoost: 4 },    // accent-tinted glass
        frosted: { outline: 0.22, sheen: 0.22, shadow: 0.28, tint: 0.0, radiusBoost: 2 }      // extra-bright, "frosted" sheen
    })

    readonly property var active: {
        const p = Config.appearance.glassPreset;
        if (p === "custom" || !presets[p])
            return { outline: Config.appearance.glassOutline, sheen: Config.appearance.glassSheen,
                      shadow: Config.appearance.glassShadow, tint: Config.appearance.glassTint, radiusBoost: 0 };
        return presets[p];
    }

    readonly property color accent: Theme.primary
    function mix(c1, c2, t) { return Qt.rgba(c1.r + (c2.r - c1.r) * t, c1.g + (c2.g - c1.g) * t, c1.b + (c2.b - c1.b) * t, 1) }

    readonly property color outline: { const base = mix(Qt.rgba(1,1,1,1), accent, active.tint); return Qt.rgba(base.r, base.g, base.b, active.outline) }
    readonly property color sheenTop: Qt.rgba(1, 1, 1, active.sheen)
    readonly property real sheenStop: 0.55
    readonly property color innerHighlight: Qt.rgba(1, 1, 1, 0.05)
    readonly property color shadowColor: Qt.rgba(0, 0, 0, active.shadow)
    readonly property int radiusBoost: active.radiusBoost

    readonly property var presetList: [
        { label: "Default", value: "default" }, { label: "iOS 26", value: "ios" },
        { label: "Minimal", value: "minimal" }, { label: "Vibrant", value: "vibrant" },
        { label: "Frosted", value: "frosted" }, { label: "Custom", value: "custom" }
    ]
}

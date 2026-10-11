// TO ADD A STYLE: add it to the Chips model and implement it in
// modules/island/Visualizer.qml (or GlowRing.qml).
import QtQuick
import qs.config
import qs.services
import qs.components

Page {
    title: "Visualizer (cava)"
    SettingRow { label: "Enabled"; hint: "Runs the cava process"
        Toggle { checked: Config.cava.enabled; onToggled: Config.cava.enabled = !Config.cava.enabled } }
    SettingRow { label: "Style" }
    Chips {
        width: parent.width; current: Config.cava.style
        model: [ { label: "Glow line", value: "glow" }, { label: "Bars", value: "bars" }, { label: "Wave", value: "wave" },
                 { label: "Pulse", value: "pulse" }, { label: "None", value: "none" } ]
        onPicked: v => Config.cava.style = v
    }
    SettingRow { label: "Rainbow colors"; hint: "Cycle hue instead of the wallpaper accent"
        Toggle { checked: Config.cava.rainbow; onToggled: Config.cava.rainbow = !Config.cava.rainbow } }
    SettingRow { label: "Sensitivity"
        SSlider { from: 0.5; to: 3; stepSize: 0.1; value: Config.cava.sensitivity; onMoved: v => Config.cava.sensitivity = v } }
    SettingRow { label: "Glow strength"
        SSlider { from: 0.2; to: 1.5; stepSize: 0.05; value: Config.cava.glowStrength; onMoved: v => Config.cava.glowStrength = v } }
}

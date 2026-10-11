import QtQuick
import qs.config
import qs.services
import qs.components

Page {
    title: "Dock"
    SettingRow { label: "Enabled"
        Toggle { checked: Config.dock.enabled; onToggled: Config.dock.enabled = !Config.dock.enabled } }
    SettingRow { label: "Auto-hide"
        Toggle { checked: Config.dock.autoHide; onToggled: Config.dock.autoHide = !Config.dock.autoHide } }
    SettingRow { label: "Reserve space"; hint: "Windows won't go under the dock"
        Toggle { checked: Config.dock.reserveSpace; onToggled: Config.dock.reserveSpace = !Config.dock.reserveSpace } }
    SettingRow { label: "Icon size"
        SSlider { from: 32; to: 96; stepSize: 2; suffix: " px"; value: Config.dock.iconSize; onMoved: v => Config.dock.iconSize = v } }
    SettingRow { label: "Magnification"
        SSlider { from: 1; to: 2.5; stepSize: 0.05; suffix: "x"; value: Config.dock.magnification; onMoved: v => Config.dock.magnification = v } }
    SettingRow { label: "Bottom margin"
        SSlider { from: 0; to: 40; stepSize: 1; suffix: " px"; value: Config.dock.bottomMargin; onMoved: v => Config.dock.bottomMargin = v } }
    SettingRow { label: "Pinned apps"; hint: "Comma-separated desktop ids. Right-click a dock icon to pin/unpin." }
    Field {
        width: parent.width
        text: Array.from(Config.dock.pinned).join(", ")
        onAccepted: t => Config.dock.pinned = t.split(",").map(x => x.trim()).filter(x => x.length)
    }
}

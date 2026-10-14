import QtQuick
import qs.config
import qs.services
import qs.components

Page {
    title: "Dock"
    SettingRow { label: "Enabled"
        Toggle { checked: Config.dock.enabled; onToggled: Config.dock.enabled = !Config.dock.enabled } }
    SettingRow { label: "Launcher button"; hint: "NixOS icon that opens the app drawer"
        Toggle { checked: Config.dock.launcher; onToggled: Config.dock.launcher = !Config.dock.launcher } }
    SettingRow { label: "Visibility"
        Chips { current: Config.dock.visibility
                model: [ { label: "Always", value: "always" }, { label: "Auto-hide", value: "autohide" }, { label: "Dodge", value: "dodge" } ]
                onPicked: v => { Config.dock.visibility = v; Config.dock.autoHide = v === "autohide" } } }
    SettingRow { label: "Reserve space"; hint: "Windows won't go under the dock"
        Toggle { checked: Config.dock.reserveSpace; onToggled: Config.dock.reserveSpace = !Config.dock.reserveSpace } }
    SettingRow { label: "Tray menu in right-click"; hint: "Mute, status, quit... from the app's tray icon"
        Toggle { checked: Config.dock.trayMenus; onToggled: Config.dock.trayMenus = !Config.dock.trayMenus } }
    SettingRow { label: "Window list in right-click"
        Toggle { checked: Config.dock.windowList; onToggled: Config.dock.windowList = !Config.dock.windowList } }
    SettingRow { label: "Running indicators"; hint: "Dots under open apps"
        Toggle { checked: Config.dock.showRunning; onToggled: Config.dock.showRunning = !Config.dock.showRunning } }
    SettingRow { label: "Corner radius"
        SSlider { from: 0; to: 40; stepSize: 1; suffix: " px"; value: Config.dock.radius; onMoved: v => Config.dock.radius = v } }
    SettingRow { label: "Icon size"
        SSlider { from: 32; to: 96; stepSize: 2; suffix: " px"; value: Config.dock.iconSize; onMoved: v => Config.dock.iconSize = v } }
    SettingRow { label: "Magnification"
        SSlider { from: 1; to: 2.5; stepSize: 0.05; suffix: "x"; value: Config.dock.magnification; onMoved: v => Config.dock.magnification = v }
    }
    SettingRow { label: "Bottom margin"
        SSlider { from: 0; to: 40; stepSize: 1; suffix: " px"; value: Config.dock.bottomMargin; onMoved: v => Config.dock.bottomMargin = v }
    }
    SettingRow { label: "Pinned apps"; hint: "Drag a pinned icon sideways to reorder. Or edit ids here."
        Field {
            width: parent.width
            text: Array.from(Config.dock.pinned).join(", ")
            onAccepted: t => Config.dock.pinned = t.split(",").map(x => x.trim()).filter(x => x.length)
        }
    }
}
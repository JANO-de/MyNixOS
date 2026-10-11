import QtQuick
import qs.config
import qs.services
import qs.components

Page {
    title: "Island"
    SettingRow { label: "Enabled"
        Toggle { checked: Config.island.enabled; onToggled: Config.island.enabled = !Config.island.enabled } }
    SettingRow { label: "Expand on hover"; hint: "Off = click the island to expand"
        Toggle { checked: Config.island.expandOnHover; onToggled: Config.island.expandOnHover = !Config.island.expandOnHover } }
    SettingRow { label: "Hover delay"
        SSlider { from: 0; to: 500; stepSize: 10; suffix: " ms"; value: Config.island.hoverDelay; onMoved: v => Config.island.hoverDelay = v } }
    SettingRow { label: "Close delay (hover guard)"
        SSlider { from: 100; to: 1000; stepSize: 25; suffix: " ms"; value: Config.island.closeDelay; onMoved: v => Config.island.closeDelay = v } }
    SettingRow { label: "Animation length"
        SSlider { from: 150; to: 900; stepSize: 10; suffix: " ms"; value: Config.island.animMs; onMoved: v => Config.island.animMs = v } }
    SettingRow { label: "Top margin"
        SSlider { from: 0; to: 40; stepSize: 1; suffix: " px"; value: Config.island.topMargin; onMoved: v => Config.island.topMargin = v } }
    SettingRow { label: "Idle width"
        SSlider { from: 160; to: 400; stepSize: 5; suffix: " px"; value: Config.island.idleWidth; onMoved: v => Config.island.idleWidth = v } }
    SettingRow { label: "Expanded width"
        SSlider { from: 560; to: 900; stepSize: 10; suffix: " px"; value: Config.island.fullWidth; onMoved: v => Config.island.fullWidth = v } }
    SettingRow { label: "Expanded height"
        SSlider { from: 180; to: 300; stepSize: 5; suffix: " px"; value: Config.island.fullHeight; onMoved: v => Config.island.fullHeight = v } }
    SettingRow { label: "24-hour clock"
        Toggle { checked: Config.island.use24h; onToggled: Config.island.use24h = !Config.island.use24h } }
    SettingRow { label: "Show weather"
        Toggle { checked: Config.island.showWeather; onToggled: Config.island.showWeather = !Config.island.showWeather } }
    SettingRow { label: "Weather location"; hint: "Empty = detect by IP"
        Field { text: Config.island.location; placeholder: "e.g. Algeciras"; onAccepted: t => Config.island.location = t } }
    SettingRow { label: "Units"
        Chips { current: Config.island.units; model: [ { label: "°C", value: "m" }, { label: "°F", value: "u" } ]
                onPicked: v => Config.island.units = v } }
}

import QtQuick
import qs.config
import qs.services
import qs.components

Page {
    title: "Desktop widgets"
    Text { text: "Drag widgets on the desktop to move them."; color: Theme.onSurfaceVariant; font.pixelSize: 12; bottomPadding: 8 }
    SettingRow { label: "Clock"
        Toggle { checked: Config.widgets.clock; onToggled: Config.widgets.clock = !Config.widgets.clock } }
    SettingRow { label: "Weather"
        Toggle { checked: Config.widgets.weather; onToggled: Config.widgets.weather = !Config.widgets.weather } }
    SettingRow { label: "Media"
        Toggle { checked: Config.widgets.media; onToggled: Config.widgets.media = !Config.widgets.media } }
    SettingRow { label: "Reset positions"
        Chips { model: [ { label: "Reset", value: "r" } ]; onPicked: v => Config.widgets.positions = ({}) } }
}

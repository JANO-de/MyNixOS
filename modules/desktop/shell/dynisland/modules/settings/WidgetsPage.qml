import QtQuick
import qs.config
import qs.services
import qs.components

Page {
    title: "Desktop widgets"
    WidgetsPreview {}
    Text { text: "Drag widgets on the desktop to move them."; color: Theme.surfaceFgDim; font.pixelSize: 12; bottomPadding: 8 }
    SettingRow { label: "Clock"
        Toggle { checked: Config.widgets.clock; onToggled: Config.widgets.clock = !Config.widgets.clock } }
    SettingRow { label: "Weather"
        Toggle { checked: Config.widgets.weather; onToggled: Config.widgets.weather = !Config.widgets.weather } }
    SettingRow { label: "Media"
        Toggle { checked: Config.widgets.media; onToggled: Config.widgets.media = !Config.widgets.media } }
    SettingRow { label: "System monitor"; hint: "CPU, RAM, disk"
        Toggle { checked: Config.widgets.system; onToggled: Config.widgets.system = !Config.widgets.system } }
    SettingRow { label: "Calendar"
        Toggle { checked: Config.widgets.calendar; onToggled: Config.widgets.calendar = !Config.widgets.calendar } }
    SettingRow { label: "Recent files"; hint: "From recently-used.xbel"
        Toggle { checked: Config.widgets.recent; onToggled: Config.widgets.recent = !Config.widgets.recent } }
    SettingRow { label: "File shelf"; hint: "Drop files on it, drag them out again"
        Toggle { checked: Config.widgets.fileShelf; onToggled: Config.widgets.fileShelf = !Config.widgets.fileShelf } }
    SettingRow { label: "Card corner radius"
        SSlider { from: 0; to: 44; stepSize: 1; suffix: " px"; value: Config.widgets.cardRadius; onMoved: v => Config.widgets.cardRadius = v } }
    SettingRow { label: "Reset positions"
        Chips { model: [ { label: "Reset", value: "r" } ]; onPicked: v => Config.widgets.positions = ({}) } }
}

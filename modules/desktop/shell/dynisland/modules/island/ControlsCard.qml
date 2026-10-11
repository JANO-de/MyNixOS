// Expanded view, right column: toggles, volume/brightness, power, settings.
// TO ADD A CONTROL: drop another IconButton/ValueSlider in the layout below.
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.config
import qs.services
import qs.components

ColumnLayout {
    id: c
    spacing: 8
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    RowLayout {
        spacing: 8
        IconButton { diameter: 38; icon: Sys.wifiOn ? "wifi" : "wifi_off"; active: Sys.wifiOn; onClicked: Sys.toggleWifi() }
        IconButton { diameter: 38; icon: Sys.btOn ? "bluetooth" : "bluetooth_disabled"; active: Sys.btOn; onClicked: Sys.toggleBt() }
        IconButton { diameter: 38; icon: Notifs.dnd ? "notifications_off" : "notifications"; active: Notifs.dnd; onClicked: Notifs.dnd = !Notifs.dnd }
        IconButton { diameter: 38; icon: "settings"; onClicked: UiState.settingsOpen = true }
    }
    ValueSlider {
        Layout.fillWidth: true
        icon: (c.audio && c.audio.muted) ? "volume_off" : "volume_up"
        value: c.audio ? c.audio.volume : 0
        onMoved: v => { if (c.audio) { c.audio.muted = false; c.audio.volume = v } }
    }
    ValueSlider {
        Layout.fillWidth: true; visible: Sys.hasBacklight
        icon: "brightness_6"; value: Sys.brightness
        onMoved: v => Sys.setBrightness(v)
    }
    Item { Layout.fillHeight: true }
    RowLayout {
        spacing: 8
        IconButton { diameter: 32; iconSize: 17; icon: "lock"; onClicked: Sys.run(Config.system.lockCmd) }
        IconButton { diameter: 32; iconSize: 17; icon: "logout"; onClicked: Sys.run(Config.system.logoutCmd) }
        IconButton { diameter: 32; iconSize: 17; icon: "restart_alt"; onClicked: Sys.run(Config.system.rebootCmd) }
        IconButton { diameter: 32; iconSize: 17; icon: "power_settings_new"; onClicked: Sys.run(Config.system.shutdownCmd) }
    }
}

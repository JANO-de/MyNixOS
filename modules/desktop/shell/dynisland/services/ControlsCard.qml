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
        Layout.alignment: Qt.AlignHCenter; spacing: 6
        IconButton { diameter: 30; iconSize: 16; icon: Sys.wifiOn ? "signal_wifi_4_bar" : "wifi_off"; active: Sys.wifiOn; onClicked: Sys.toggleWifi()
                      TapHandler { acceptedButtons: Qt.RightButton; onTapped: UiState.openPanel("wifi") } }   // right-click: network list
        IconButton { diameter: 30; iconSize: 16; icon: Sys.btOn ? "bluetooth_connected" : "bluetooth_disabled"; active: Sys.btOn; onClicked: Sys.toggleBt()
                      TapHandler { acceptedButtons: Qt.RightButton; onTapped: UiState.openPanel("bluetooth") } }   // right-click: device list
        IconButton { diameter: 30; iconSize: 16; icon: Notifs.dnd ? "notifications_off" : "notifications"; active: Notifs.dnd; onClicked: Notifs.dnd = !Notifs.dnd
                      TapHandler { acceptedButtons: Qt.RightButton; onTapped: UiState.openPanel("history") } }   // right-click: history
        IconButton { diameter: 30; iconSize: 16; icon: "photo_camera"; onClicked: Sys.screenshot() }
    }
    ValueSlider {
        Layout.fillWidth: true
        icon: (c.audio && c.audio.muted) ? "volume_off" : "volume_up"
        value: c.audio ? c.audio.volume : 0
        onMoved: v => { if (c.audio) { c.audio.muted = false; c.audio.volume = v } }
        TapHandler { acceptedButtons: Qt.RightButton; onTapped: UiState.openPanel("audio") }   // right-click: mixer
    }
    ValueSlider {
        Layout.fillWidth: true; visible: Sys.hasBacklight
        icon: "brightness_6"; value: Sys.brightness
        onMoved: v => Sys.setBrightness(v)
    }
    Item { Layout.fillHeight: true }
    RowLayout {
        Layout.alignment: Qt.AlignHCenter; spacing: 6
        IconButton { diameter: 30; iconSize: 16; icon: "tune"; onClicked: UiState.settingsOpen = true }
        IconButton { diameter: 30; iconSize: 16; icon: "sentiment_satisfied"; onClicked: UiState.openPanel("emoji"); tip: "Emoji picker" }
        IconButton { diameter: 30; iconSize: 16; icon: "colorize"; onClicked: Sys.pickColor(); tip: Sys.lastColor !== "" ? "Pick color (last " + Sys.lastColor + ")" : "Color picker" }
        IconButton { diameter: 30; iconSize: 16; icon: "lock"; onClicked: Sys.lock() }
        IconButton { diameter: 30; iconSize: 16; icon: "logout"; onClicked: Sys.run(Config.system.logoutCmd) }
        IconButton { diameter: 30; iconSize: 16; icon: "power_settings_new"; onClicked: UiState.openPanel("power") }   // lock / logout / suspend / reboot / shutdown
    }
}

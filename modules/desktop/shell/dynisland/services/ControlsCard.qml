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
        IconButton { diameter: 38; icon: Sys.wifiOn ? "wifi" : "wifi_off"; active: Sys.wifiOn; onClicked: Sys.toggleWifi()
                      TapHandler { acceptedButtons: Qt.RightButton; onTapped: UiState.openPanel("wifi") } }   // right-click: network list
        IconButton { diameter: 38; icon: Sys.btOn ? "bluetooth" : "bluetooth_disabled"; active: Sys.btOn; onClicked: Sys.toggleBt()
                      TapHandler { acceptedButtons: Qt.RightButton; onTapped: UiState.openPanel("bluetooth") } }   // right-click: device list
        IconButton { diameter: 38; icon: Notifs.dnd ? "notifications_off" : "notifications"; active: Notifs.dnd; onClicked: Notifs.dnd = !Notifs.dnd
                      TapHandler { acceptedButtons: Qt.RightButton; onTapped: UiState.openPanel("history") } }   // right-click: history
        IconButton { diameter: 38; icon: "photo_camera"; onClicked: Sys.screenshot() }
        IconButton { diameter: 38; icon: "settings"; onClicked: UiState.settingsOpen = true }
    }
    RowLayout {
        spacing: 8
        IconButton { diameter: 32; iconSize: 17; icon: "nightlight"; active: Sys.nightLight; onClicked: Sys.toggleNightLight()
                     tip: Sys.nightLight ? "Night light: on" : "Night light: off" }
        IconButton { diameter: 32; iconSize: 17; icon: Sys.inhibit ? "visibility" : "visibility_off"; active: Sys.inhibit; onClicked: Sys.toggleInhibit()
                     tip: Sys.inhibit ? "Keep awake: on (screen won't sleep)" : "Keep awake: off" }
        IconButton { diameter: 32; iconSize: 17; icon: Sys.recording ? "stop_circle" : "fiber_manual_record"; active: Sys.recording; onClicked: Sys.toggleRecording()
                     tip: Sys.recording ? "Stop screen recording" : "Record screen (pick area)" }
        IconButton { diameter: 32; iconSize: 17; icon: "center_focus_strong"; active: Sys.focusMode; onClicked: Sys.toggleFocus()
                     tip: Sys.focusMode ? "Focus mode: on (DND + dim)" : "Focus mode: off" }
        IconButton { visible: Sys.powerProfile !== ""; diameter: 32; iconSize: 17
                     icon: Sys.powerProfile === "performance" ? "speed" : (Sys.powerProfile === "power-saver" ? "battery_saver" : "balance")
                     active: Sys.powerProfile !== "balanced"; onClicked: Sys.cyclePowerProfile(); tip: "Power profile: " + Sys.powerProfile }
        IconButton { diameter: 32; iconSize: 17; icon: "content_paste"; onClicked: UiState.openPanel("clipboard"); tip: "Clipboard history" }
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
        spacing: 8
        IconButton { diameter: 32; iconSize: 17; icon: "mood"; onClicked: UiState.openPanel("emoji"); tip: "Emoji picker" }
        IconButton { diameter: 32; iconSize: 17; icon: "colorize"; onClicked: Sys.pickColor(); tip: Sys.lastColor !== "" ? "Pick color (last " + Sys.lastColor + ")" : "Color picker" }
        IconButton { diameter: 32; iconSize: 17; icon: "lock"; onClicked: Sys.lock() }
        IconButton { diameter: 32; iconSize: 17; icon: "logout"; onClicked: Sys.run(Config.system.logoutCmd) }
        IconButton { diameter: 32; iconSize: 17; icon: "power_settings_new"; onClicked: UiState.openPanel("power") }   // lock / logout / suspend / reboot / shutdown
    }
}

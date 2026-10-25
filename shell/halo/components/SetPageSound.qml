import QtQuick
import Quickshell
import qs.services

// Settings > Sound: volume and mute.
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: System.refresh()

    function toggleMute() {
        System.muted = !System.muted;
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", System.muted ? "1" : "0"]);
    }

    SetGroup {
        title: "Volume"
        QsSlider {
            width: parent.width
            label: "Volume"
            value: System.muted ? 0 : System.volume
            onMoved: v => System.setVolume(v)
        }
    }

    SetGroup {
        SetRow {
            glyph: "♪"
            title: "Mute"
            subtitle: System.muted ? "Sound is off" : "Sound is on"
            onClicked: page.toggleMute()

            SetSwitch {
                checked: System.muted
                onToggled: page.toggleMute()
            }
        }
    }
}

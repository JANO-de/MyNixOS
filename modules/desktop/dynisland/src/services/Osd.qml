// =============================================================================
//  Osd — volume/brightness feedback; the island morphs into a small bar.
//  Volume is detected via PipeWire. For brightness keys bind in niri:
//    spawn "qs" "-c" "dynisland" "ipc" "call" "osd" "show" "brightness" "0.5"
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root
    property bool active: false
    property string kind: "volume"   // volume | brightness
    property real value: 0
    property bool armed: false       // ignore the PipeWire burst at startup

    function show(k, v) {
        if (!armed) return;
        kind = k; value = v; active = true; hideT.restart();
    }

    Timer { interval: 3000; running: true; onTriggered: root.armed = true }
    Timer { id: hideT; interval: 1600; onTriggered: root.active = false }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        ignoreUnknownSignals: true
        function onVolumeChanged() { root.show("volume", Pipewire.defaultAudioSink.audio.volume) }
        function onMutedChanged() {
            const a = Pipewire.defaultAudioSink.audio;
            root.show("volume", a.muted ? 0 : a.volume);
        }
    }
}

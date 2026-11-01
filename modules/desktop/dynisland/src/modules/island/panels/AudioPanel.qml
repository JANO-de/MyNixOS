// Volume mixer: master volume, output device, and one slider per playing app (PipeWire).
// App streams are told apart by their media.class so this does not depend on isSink semantics.
import QtQuick
import Quickshell.Services.Pipewire
import qs.services
import qs.components

PanelFrame {
    id: p
    title: "Volume"; icon: "volume_up"
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var nodes: Pipewire.nodes.values
    readonly property var apps: nodes.filter(n => n.audio && n.isStream && (n.properties["media.class"] || "") === "Stream/Output/Audio")
    readonly property var sinks: nodes.filter(n => n.audio && !n.isStream && (n.properties["media.class"] || "") === "Audio/Sink")
    function nameOf(n) { return n.properties["application.name"] || n.description || n.nickname || n.name }

    PwObjectTracker { objects: p.nodes }     // required so node.audio (volume/mute) is bound

    Column {
        anchors.fill: parent; spacing: 10
        ValueSlider {
            width: parent.width
            icon: (p.sink && p.sink.audio && p.sink.audio.muted) ? "volume_off" : "volume_up"
            value: p.sink && p.sink.audio ? p.sink.audio.volume : 0
            onMoved: v => { if (p.sink && p.sink.audio) { p.sink.audio.muted = false; p.sink.audio.volume = v } }
        }

        // output devices
        Flow {
            width: parent.width; spacing: 6; visible: p.sinks.length > 1
            Repeater {
                model: p.sinks
                Rectangle {
                    required property var modelData
                    readonly property bool cur: p.sink && modelData.id === p.sink.id
                    height: 28; width: Math.min(parent.width, lbl.implicitWidth + 24); radius: 14
                    color: cur ? Theme.primary : "#18ffffff"
                    Text { id: lbl; anchors.centerIn: parent; width: Math.min(implicitWidth, parent.parent.width - 24); elide: Text.ElideRight
                           text: modelData.description || modelData.name; font.pixelSize: 12; color: parent.cur ? Theme.primaryFg : "white" }
                    MouseArea { anchors.fill: parent; onClicked: Pipewire.preferredDefaultAudioSink = modelData }
                }
            }
        }

        Text { text: "Apps"; color: "#88ffffff"; font.pixelSize: 11; font.bold: true }
        Flickable {
            width: parent.width; height: parent.height - (p.sinks.length > 1 ? 130 : 96); clip: true
            contentHeight: al.height; boundsBehavior: Flickable.StopAtBounds
            Column {
                id: al; width: parent.width; spacing: 8
                Text { visible: p.apps.length === 0; text: "Nothing is playing"; color: "#77ffffff"; font.pixelSize: 12 }
                Repeater {
                    model: p.apps
                    Column {
                        required property var modelData
                        width: al.width; spacing: 2
                        Text { width: parent.width; elide: Text.ElideRight; text: p.nameOf(modelData); color: "white"; font.pixelSize: 12 }
                        ValueSlider {
                            width: parent.width
                            icon: modelData.audio && modelData.audio.muted ? "volume_off" : "volume_up"
                            value: modelData.audio ? modelData.audio.volume : 0
                            onMoved: v => { if (modelData.audio) { modelData.audio.muted = false; modelData.audio.volume = v } }
                        }
                    }
                }
            }
        }
    }
}

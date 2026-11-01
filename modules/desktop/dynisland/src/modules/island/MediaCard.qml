// Expanded view, left column: now playing + transport controls.
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.components

Item {
    id: c
    property bool active: false
    readonly property var p: Media.player

    // MPRIS doesn't push position updates: nudge once a second while visible.
    Timer { interval: 1000; repeat: true; running: c.active && Media.playing; onTriggered: if (c.p) c.p.positionChanged() }

    ColumnLayout {
        anchors.fill: parent; spacing: 8; visible: c.p !== null
        RowLayout {
            spacing: 10
            ClippingRectangle {
                width: 62; height: 62; radius: 18; color: "#2a2a2a"
                Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 124 }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { Layout.fillWidth: true; elide: Text.ElideRight; text: Media.title; color: "white"; font.pixelSize: 14; font.weight: Font.DemiBold }
                Text { Layout.fillWidth: true; elide: Text.ElideRight; text: Media.artist; color: "#99ffffff"; font.pixelSize: 12 }
            }
        }
        Rectangle {   // progress
            Layout.fillWidth: true; height: 5; radius: 2.5; color: "#26ffffff"
            Rectangle { radius: 2.5; height: parent.height; color: Theme.primary
                        width: (c.p && c.p.length > 0) ? parent.width * Math.min(1, c.p.position / c.p.length) : 0 }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: 14
            IconButton { flat: true; icon: "skip_previous"; diameter: 34; iconSize: 22; onClicked: c.p && c.p.previous() }
            IconButton { icon: Media.playing ? "pause" : "play_arrow"; diameter: 40; iconSize: 24; active: true; onClicked: c.p && c.p.togglePlaying() }
            IconButton { flat: true; icon: "skip_next"; diameter: 34; iconSize: 22; onClicked: c.p && c.p.next() }
        }
    }
    ColumnLayout {
        anchors.centerIn: parent; visible: c.p === null; spacing: 6
        Icon { Layout.alignment: Qt.AlignHCenter; name: "music_off"; size: 30; color: "#66ffffff" }
        Text { text: "Nothing playing"; color: "#77ffffff"; font.pixelSize: 12 }
    }
}

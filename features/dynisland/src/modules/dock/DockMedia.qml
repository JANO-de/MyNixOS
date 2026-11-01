// =============================================================================
//  DockMedia — now-playing card inside the dock (end4-pC style): soft blurred
//  cover as background, cover thumbnail, title / artist, prev / play / next.
//  Shown by Dock.qml when Config.dock.media is on and a player exists.
//  Height comes from the parent (dock icon size); width is fixed at 250.
// =============================================================================
import QtQuick
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

ClippingRectangle {
    id: card
    width: 250
    radius: Math.min(18, height / 2.4)
    color: Theme.surfaceContainer
    border.width: 1; border.color: Glass.outline

    // blurred background: a tiny decode of the cover, scaled up smoothly
    Image {
        anchors.fill: parent; visible: Media.art !== ""; asynchronous: true; smooth: true
        source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(24, 24); opacity: 0.8
    }
    Rectangle { anchors.fill: parent; color: "#80000000" }   // scrim: keeps text readable on any cover

    Row {
        anchors { fill: parent; margins: 8 }
        spacing: 10
        ClippingRectangle {   // cover thumbnail
            id: thumb
            width: parent.height; height: parent.height; radius: 10; color: Theme.surfaceContainerHigh
            Image { anchors.fill: parent; visible: Media.art !== ""; asynchronous: true; source: Media.art
                    fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(160, 160) }
            Icon { visible: Media.art === ""; anchors.centerIn: parent; name: "music_note"; size: 22; color: Theme.surfaceFgDim }
        }
        Column {
            width: parent.width - thumb.width - ctl.width - 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text { width: parent.width; elide: Text.ElideRight; text: Media.title; color: "white"
                   font.pixelSize: 13; font.weight: Font.DemiBold }
            Text { width: parent.width; elide: Text.ElideRight; text: Media.artist; color: "#ccffffff"
                   font.pixelSize: 11; visible: text !== "" }
        }
        Row {
            id: ctl
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            IconButton { icon: "skip_previous"; diameter: 28; iconSize: 18
                         opacity: Media.player ? 1 : 0.4; onClicked: if (Media.player) Media.player.previous() }
            IconButton { icon: Media.playing ? "pause" : "play_arrow"; active: true; diameter: 32; iconSize: 20
                         onClicked: if (Media.player) Media.player.togglePlaying() }
            IconButton { icon: "skip_next"; diameter: 28; iconSize: 18
                         opacity: Media.player ? 1 : 0.4; onClicked: if (Media.player) Media.player.next() }
        }
    }
}

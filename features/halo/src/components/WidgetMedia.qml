import QtQuick
import Quickshell.Services.Mpris
import qs.services

// Now playing (any MPRIS player).
Item {
    id: root

    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    Text {
        anchors.top: parent.top
        text: "Now playing"
        color: Theme.dim
        font.pixelSize: 13
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: 4

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.player ? (root.player.trackTitle || "Unknown") : "Nothing playing"
            color: Theme.text
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: root.player !== null
            text: root.player ? (root.player.trackArtist || "") : ""
            color: Theme.dim
            font.pixelSize: 14
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 28
        visible: root.player !== null

        Repeater {
            model: [
                { glyph: "‹‹", act: "prev" },
                { glyph: root.player && root.player.isPlaying ? "❚❚" : "▶", act: "toggle" },
                { glyph: "››", act: "next" }
            ]
            Item {
                required property var modelData
                width: 44
                height: 36
                scale: ma.pressed ? 0.85 : 1
                Behavior on scale { NumberAnimation { duration: 90 } }
                Text {
                    anchors.centerIn: parent
                    text: parent.modelData.glyph
                    color: Theme.text
                    font.pixelSize: 22
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    onClicked: {
                        if (!root.player)
                            return;
                        if (parent.modelData.act === "prev")
                            root.player.previous();
                        else if (parent.modelData.act === "next")
                            root.player.next();
                        else
                            root.player.togglePlaying();
                    }
                }
            }
        }
    }
}

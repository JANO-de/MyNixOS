// MPRIS: Media.player (null if none), Media.title / artist / art / playing.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    // Prefer a player that is playing, else the first.
    readonly property var player: {
        const ps = Mpris.players.values;
        for (const p of ps) if (p.isPlaying) return p;
        return ps.length ? ps[0] : null;
    }
    readonly property bool playing: player ? player.isPlaying : false
    readonly property string title: player ? (player.trackTitle || "Unknown") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string art: player ? (player.trackArtUrl || "") : ""
}

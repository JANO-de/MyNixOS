import QtQuick
import QtMultimedia
import qs.common

// Inline video player. Loaded lazily by GViewer; if QtMultimedia is missing the Loader errors and the viewer falls back to xdg-open.
Item {
    id: vp
    property string src: ""
    onSrcChanged: {
        if (src !== "") {
            player.source = src;
            player.play();
        }
    }
    function fmt(ms) {
        const s = Math.floor(ms / 1000);
        return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2);
    }

    MediaPlayer {
        id: player
        audioOutput: AudioOutput {}
        videoOutput: out
    }
    VideoOutput {
        id: out
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
    }
    TapHandler {
        onTapped: player.playbackState === MediaPlayer.PlayingState ? player.pause() : player.play()
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 190
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        height: 36
        radius: 18
        color: Qt.rgba(0, 0, 0, 0.55)
        Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: vp.fmt(player.position); color: "#ffffff"; font.pixelSize: 13 }
        Rectangle {
            x: 64
            width: parent.width - 128
            height: 4
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(1, 1, 1, 0.3)
            Rectangle { width: player.duration > 0 ? parent.width * player.position / player.duration : 0; height: parent.height; radius: 2; color: AppTheme.accent }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -12
                onClicked: mouse => { if (player.duration > 0) player.position = player.duration * Math.max(0, Math.min(1, (mouse.x + 12) / (parent.width))); }
            }
        }
        Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: vp.fmt(player.duration); color: "#ffffff"; font.pixelSize: 13 }
    }
    Component.onDestruction: player.stop()
}

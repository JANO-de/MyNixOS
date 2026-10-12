// Cards on the lock screen: media, weather, next events.
// Each card: shown if its Config.lock.* toggle is on, placed at Config.lock.positions[wid]
// (center as fractions of the screen; edited in Settings > Lock screen).
import QtQuick
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

Item {
    id: root   // fills the whole lock surface

    // Shared card: glass look + saved/default position. `parent` is root.
    component Card: Rectangle {
        required property string wid
        property real defX: 0.5
        property real defY: 0.9
        default property alias content: inner.data
        readonly property var saved: Config.lock.positions[wid]
        readonly property real fx: saved ? saved.x : defX
        readonly property real fy: saved ? saved.y : defY
        width: inner.implicitWidth + 36; height: inner.implicitHeight + 28
        // center on (fx, fy), then keep fully on screen
        x: Math.max(0, Math.min(parent.width - width,  fx * parent.width  - width  / 2))
        y: Math.max(0, Math.min(parent.height - height, fy * parent.height - height / 2))
        radius: Config.widgets.cardRadius; color: "#33ffffff"
        border.width: 1; border.color: "#22ffffff"
        Item { id: inner; x: 18; y: 14; implicitWidth: childrenRect.width; implicitHeight: childrenRect.height }
    }

    // ---- Media (visible only when a player exists)
    Card {
        wid: "media"; defX: 0.2; defY: 0.86
        visible: Config.lock.media && Media.player !== null
        Row {
            spacing: 14
            ClippingRectangle {
                width: 64; height: 64; radius: 14; color: "#222"
                Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 128 }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: 4
                Text { width: 170; elide: Text.ElideRight; text: Media.title; color: "white"; font.pixelSize: 15; font.weight: Font.DemiBold }
                Text { width: 170; elide: Text.ElideRight; text: Media.artist; color: "#aaffffff"; font.pixelSize: 12 }
                Row {
                    spacing: 14
                    Repeater {   // transport buttons: icon + MouseArea
                        model: [ { i: "skip_previous", a: 0 }, { i: Media.playing ? "pause" : "play_arrow", a: 1 }, { i: "skip_next", a: 2 } ]
                        Item {
                            required property var modelData
                            width: 26; height: 26
                            Icon { anchors.centerIn: parent; name: parent.modelData.i; size: 24; color: "white" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const p = Media.player; if (!p) return;
                                    if (parent.modelData.a === 0) p.previous();
                                    else if (parent.modelData.a === 1) p.togglePlaying();
                                    else p.next();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- Weather
    Card {
        wid: "weather"; defX: 0.5; defY: 0.92
        visible: Config.lock.weather
        Row {
            spacing: 14
            Icon { name: Weather.icon; size: 44; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: Weather.temp; color: "white"; font.pixelSize: 28; font.weight: Font.DemiBold }
                Text { text: Weather.cond; color: "#ccffffff"; font.pixelSize: 13 }
            }
        }
    }

    // ---- Next events (up to 3)
    Card {
        wid: "calendar"; defX: 0.8; defY: 0.86
        visible: Config.lock.calendar
        Column {
            spacing: 6
            Text { text: "Upcoming"; color: "#99ffffff"; font.pixelSize: 11; font.weight: Font.Medium }
            Text { visible: Agenda.upcoming(1).length === 0; text: "No events"; color: "#ccffffff"; font.pixelSize: 13 }
            Repeater {
                model: Agenda.upcoming(3)
                Row {
                    required property var modelData
                    spacing: 10
                    Rectangle { width: 4; height: 30; radius: 2; color: Theme.primary }
                    Column {
                        Text { width: 190; elide: Text.ElideRight; text: modelData.title; color: "white"; font.pixelSize: 13 }
                        Text { text: modelData.allDay ? Qt.formatDate(modelData.start, "ddd d MMM")
                                                       : Qt.formatDateTime(modelData.start, "ddd d MMM, HH:mm")
                               color: "#aaffffff"; font.pixelSize: 11 }
                    }
                }
            }
        }
    }
}

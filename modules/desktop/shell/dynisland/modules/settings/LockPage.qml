// Settings > Lock screen: toggle cards and drag them around a mini lock screen.
// Positions are saved as fractions (center of card / screen size) in Config.lock.positions.
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Page {
    id: pg
    title: "Lock screen"

    // first monitor's size -> board aspect ratio and card scale
    readonly property real sw: Quickshell.screens.length ? Quickshell.screens[0].width : 1920
    readonly property real sh: Quickshell.screens.length ? Quickshell.screens[0].height : 1080

    Text { text: "Drag cards to move them. Double-click a card to toggle it."
           color: Theme.surfaceFgDim; font.pixelSize: 12; bottomPadding: 8 }

    // Draggable stand-in for one lock card (approximate real size: cw x ch screen px).
    // `parent` is the board.
    component Chip: Rectangle {
        required property string wid
        required property string label
        required property string ico
        property real cw: 200
        property real ch: 90
        property real defX: 0.5
        property real defY: 0.9
        readonly property bool shown: Config.lock[wid]
        readonly property var saved: Config.lock.positions[wid]
        readonly property real fx: saved ? saved.x : defX
        readonly property real fy: saved ? saved.y : defY
        property point d: Qt.point(0, 0)           // live drag offset (board px)

        width: cw * parent.sc; height: ch * parent.sc
        x: Math.max(0, Math.min(parent.width  - width,  fx * parent.width  + (drag.active ? d.x : 0) - width  / 2))
        y: Math.max(0, Math.min(parent.height - height, fy * parent.height + (drag.active ? d.y : 0) - height / 2))
        radius: 10
        color: shown ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.08)
        border.width: 1; border.color: shown ? Theme.primary : Glass.outline
        opacity: shown ? 1 : 0.55
        Behavior on color { ColorAnimation { duration: 120 } }

        Column {
            anchors.centerIn: parent; spacing: 2
            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: parent.parent.ico; size: 18; color: "white" }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.parent.label
                   color: "white"; font.pixelSize: 11 }
        }
        TapHandler { onDoubleTapped: Config.lock[wid] = !Config.lock[wid] }
        DragHandler {
            id: drag; target: null
            onTranslationChanged: parent.d = translation
            onActiveChanged: if (!active) {
                const p = parent;
                // clamp the final center so the card stays inside the board
                const cx = Math.max(p.width / 2,  Math.min(p.parent.width  - p.width / 2,  p.fx * p.parent.width  + p.d.x));
                const cy = Math.max(p.height / 2, Math.min(p.parent.height - p.height / 2, p.fy * p.parent.height + p.d.y));
                Config.setLockPos(p.wid, cx / p.parent.width, cy / p.parent.height);
                p.d = Qt.point(0, 0);
            }
        }
    }

    // ---- the board (mini lock screen)
    Rectangle {
        id: board
        property real sc: width / pg.sw            // screen px -> board px
        width: Math.min(parent.width, 640); height: width * pg.sh / pg.sw
        radius: 14; color: "#222"; clip: true; border.width: 1; border.color: Glass.outline

        Image {
            anchors.fill: parent; asynchronous: true; fillMode: Image.PreserveAspectCrop
            source: Config.appearance.wallpaper ? "file://" + Config.appearance.wallpaper : ""
            sourceSize.width: 640
        }
        Rectangle { anchors.fill: parent; color: "#66000000" }

        // fixed part of the real lock screen (not movable)
        Rectangle {
            anchors.centerIn: parent; width: 230 * board.sc; height: 400 * board.sc; radius: 12
            color: "transparent"; border.width: 1; border.color: "#33ffffff"
            Text { anchors.centerIn: parent; text: "clock +\npassword"; horizontalAlignment: Text.AlignHCenter
                   color: "#88ffffff"; font.pixelSize: 11 }
        }

        Chip { wid: "media";    label: "Media";    ico: "music_note";   cw: 330; ch: 92;  defX: 0.2; defY: 0.86 }
        Chip { wid: "weather";  label: "Weather";  ico: "sunny";        cw: 190; ch: 92;  defX: 0.5; defY: 0.92 }
        Chip { wid: "calendar"; label: "Calendar"; ico: "calendar_month"; cw: 290; ch: 130; defX: 0.8; defY: 0.86 }
    }

    Item { width: 1; height: 10 }
    SettingRow { label: "Media player"; hint: "Only shown while something is playing"
        Toggle { checked: Config.lock.media; onToggled: Config.lock.media = !Config.lock.media } }
    SettingRow { label: "Weather"
        Toggle { checked: Config.lock.weather; onToggled: Config.lock.weather = !Config.lock.weather } }
    SettingRow { label: "Calendar"; hint: "Next 3 events"
        Toggle { checked: Config.lock.calendar; onToggled: Config.lock.calendar = !Config.lock.calendar } }
    SettingRow { label: "Reset positions"
        Chips { model: [ { label: "Reset", value: "r" } ]; onPicked: v => Config.lock.positions = ({}) } }
}

// Mini live preview of the desktop widgets: a small dark "desktop" with a
// card per enabled widget, matching the corner radius slider below.
import QtQuick
import qs.config
import qs.services
import qs.components

Rectangle {
    id: board
    width: parent ? parent.width : 400
    height: 120
    radius: 16; color: "#1a1a1a"; clip: true
    Image { anchors.fill: parent; asynchronous: true; opacity: 0.5; fillMode: Image.PreserveAspectCrop
            source: Config.appearance.wallpaper ? "file://" + Config.appearance.wallpaper : ""; sourceSize.width: 400 }

    component Mini: Rectangle {
        property string ico: ""
        property string label: ""
        width: 78; height: 56; radius: Math.min(22, Config.widgets.cardRadius * 0.5 + 4)
        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, Config.appearance.glassOpacity)
        border.width: 1; border.color: Glass.outline
        Column { anchors.centerIn: parent; spacing: 3
            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: parent.parent.ico; size: 16; color: Theme.primary }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.parent.label; color: "white"; font.pixelSize: 10 }
        }
    }
    Flow {
        anchors { fill: parent; margins: 12 } spacing: 10
        Mini { visible: Config.widgets.clock;    ico: "schedule";       label: "Clock" }
        Mini { visible: Config.widgets.weather;  ico: "sunny";          label: "Weather" }
        Mini { visible: Config.widgets.media;    ico: "music_note";     label: "Media" }
        Mini { visible: Config.widgets.system;   ico: "monitor_heart";  label: "System" }
        Mini { visible: Config.widgets.calendar; ico: "calendar_month"; label: "Calendar" }
    }
    Text {   // outside the Flow: positioners ignore/complain about anchors on their children
        anchors.centerIn: parent
        visible: !Config.widgets.clock && !Config.widgets.weather && !Config.widgets.media && !Config.widgets.system && !Config.widgets.calendar
        text: "No widgets enabled"; color: "#88ffffff"; font.pixelSize: 12
    }
}

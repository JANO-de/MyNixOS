// Desktop widget layer (above wallpaper, below windows). Input masked to the cards.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "dynisland-widgets"
    mask: Region { Region { item: clockW } Region { item: weatherW } Region { item: mediaW } }

    // ---- Clock
    DesktopWidget {
        id: clockW; wid: "clock"; defX: 80; defY: 100
        visible: Config.widgets.clock; width: visible ? implicitWidth : 0; height: visible ? implicitHeight : 0
        Column {
            spacing: 2
            Text { text: Clock.time; color: "white"; font.pixelSize: 64; font.weight: Font.Bold }
            Text { text: Clock.dateLong; color: "#ccffffff"; font.pixelSize: 16 }
        }
    }

    // ---- Weather
    DesktopWidget {
        id: weatherW; wid: "weather"; defX: 80; defY: 280
        visible: Config.widgets.weather; width: visible ? implicitWidth : 0; height: visible ? implicitHeight : 0
        Row {
            spacing: 14
            Icon { name: Weather.icon; size: 46; color: Theme.primary }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: Weather.temp; color: "white"; font.pixelSize: 30; font.weight: Font.DemiBold }
                Text { text: Weather.cond; color: "#ccffffff"; font.pixelSize: 13 }
            }
        }
    }

    // ---- Media
    DesktopWidget {
        id: mediaW; wid: "media"; defX: 80; defY: 400
        visible: Config.widgets.media; width: visible ? implicitWidth : 0; height: visible ? implicitHeight : 0
        Row {
            spacing: 14
            ClippingRectangle {
                width: 64; height: 64; radius: 16; color: "#222"
                Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 128 }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter; width: 170; spacing: 2
                Text { width: parent.width; elide: Text.ElideRight; text: Media.player ? Media.title : "Nothing playing"
                       color: "white"; font.pixelSize: 15; font.weight: Font.DemiBold }
                Text { width: parent.width; elide: Text.ElideRight; text: Media.artist; color: "#aaffffff"; font.pixelSize: 12 }
            }
        }
    }
}

// Collapsed pill: [art | date]  time  [mini-eq | weather]
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

Item {
    id: v
    property bool active: false
    anchors.fill: parent
    opacity: active ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 150 } }

    RowLayout {
        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
        spacing: 8

        // left slot: album art while playing, else the date
        Item {
            Layout.preferredWidth: 64; Layout.fillHeight: true
            ClippingRectangle {
                visible: Media.playing; width: 24; height: 24; radius: 7; color: "#222"
                anchors.verticalCenter: parent.verticalCenter
                Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 48 }
            }
            Text { visible: !Media.playing; anchors.verticalCenter: parent.verticalCenter
                   text: Clock.dayShort; color: "#bbffffff"; font.pixelSize: 13; font.weight: Font.Medium }
        }

        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
               text: Clock.time; color: "white"; font.pixelSize: 15; font.weight: Font.DemiBold }

        // right slot: mini equalizer while playing, else weather
        Item {
            Layout.preferredWidth: 64; Layout.fillHeight: true
            Row {
                visible: Media.playing && Config.cava.style !== "none"
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 2
                Repeater {
                    model: 5
                    Rectangle {
                        width: 3; radius: 1.5; color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                        height: 4 + Math.min(1, (Cava.values[index * 4] || 0) * Config.cava.sensitivity) * 16
                    }
                }
            }
            Row {
                visible: !(Media.playing && Config.cava.style !== "none") && Config.island.showWeather
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 4
                Icon { name: Weather.icon; size: 16; color: "#ddffffff" }
                Text { text: Weather.temp; color: "#ddffffff"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}

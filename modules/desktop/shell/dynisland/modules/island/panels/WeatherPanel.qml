// Current conditions, next hours, 3-day forecast (data: services/Weather.qml, wttr.in).
import QtQuick
import qs.services
import qs.components

PanelFrame {
    title: Weather.detail && Weather.detail.place ? Weather.detail.place : "Weather"; icon: "partly_cloudy_day"

    Column {
        anchors.fill: parent; spacing: 12

        Row {
            spacing: 16
            Icon { name: Weather.icon; size: 54; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: Weather.temp; color: "white"; font.pixelSize: 36; font.weight: Font.Bold }
                Text { text: Weather.cond; color: "#bbffffff"; font.pixelSize: 14 }
            }
            Grid {
                visible: Weather.detail !== null; columns: 2; columnSpacing: 18; rowSpacing: 2; anchors.verticalCenter: parent.verticalCenter
                Text { text: "Feels"; color: "#88ffffff"; font.pixelSize: 12 }
                Text { text: Weather.detail ? Weather.detail.feels + Weather.unitT : ""; color: "white"; font.pixelSize: 12 }
                Text { text: "Humidity"; color: "#88ffffff"; font.pixelSize: 12 }
                Text { text: Weather.detail ? Weather.detail.humidity + "%" : ""; color: "white"; font.pixelSize: 12 }
                Text { text: "Wind"; color: "#88ffffff"; font.pixelSize: 12 }
                Text { text: Weather.detail ? Weather.detail.wind + " " + Weather.unitW + " " + Weather.detail.windDir : ""; color: "white"; font.pixelSize: 12 }
                Text { text: "UV"; color: "#88ffffff"; font.pixelSize: 12 }
                Text { text: Weather.detail ? Weather.detail.uv : ""; color: "white"; font.pixelSize: 12 }
            }
        }

        // next hours
        Row {
            visible: Weather.detail !== null; spacing: 4
            Repeater {
                model: Weather.detail ? Weather.detail.hours : []
                Rectangle {
                    required property var modelData
                    width: 46; height: 70; radius: 14; color: "#14ffffff"
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.time; color: "#99ffffff"; font.pixelSize: 10 }
                        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.iconFor(modelData.cond); size: 20; color: "white" }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.temp + "°"; color: "white"; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                }
            }
        }

        // forecast days
        Column {
            visible: Weather.detail !== null; width: parent.width; spacing: 4
            Repeater {
                model: Weather.detail ? Weather.detail.days : []
                Row {
                    required property var modelData
                    required property int index
                    width: parent.width; height: 24; spacing: 10
                    Text { width: 70; text: index === 0 ? "Today" : Qt.formatDate(new Date(modelData.date + "T12:00:00"), "ddd d"); color: "white"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                    Icon { name: Weather.iconFor(modelData.cond); size: 20; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: 150; elide: Text.ElideRight; text: modelData.cond; color: "#aaffffff"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: modelData.lo + "° / " + modelData.hi + "°"; color: "white"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
        Text { visible: Weather.detail === null; text: "Loading forecast..."; color: "#99ffffff"; font.pixelSize: 13 }
    }
}

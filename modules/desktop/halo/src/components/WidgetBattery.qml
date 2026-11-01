import QtQuick
import Quickshell.Services.UPower
import qs.services

Item {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property int pct: dev ? Math.round(dev.percentage * 100) : -1
    readonly property bool charging: dev ? dev.state === UPowerDeviceState.Charging : false

    Text {
        anchors.top: parent.top
        text: "Battery"
        color: Theme.dim
        font.pixelSize: 13
    }

    Text {
        anchors.centerIn: parent
        text: root.pct >= 0 ? root.pct + "%" : "--"
        color: Theme.text
        font.pixelSize: Math.min(root.width, root.height) * 0.3
        font.weight: Font.Light
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 10
        radius: 5
        color: Qt.rgba(1, 1, 1, 0.14)

        Rectangle {
            width: parent.width * Math.max(0, root.pct) / 100
            height: parent.height
            radius: 5
            color: root.charging ? "#7bd88f" : (root.pct >= 0 && root.pct < 20 ? "#ff6b6b" : Theme.text)
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.charging ? "Charging" : ""
        color: Theme.dim
        font.pixelSize: 12
    }
}

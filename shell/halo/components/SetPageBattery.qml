import QtQuick
import Quickshell.Services.UPower
import qs.services

// Settings > Battery: level, state, time left, power profile.
Column {
    id: page

    readonly property var dev: UPower.displayDevice
    readonly property int pct: dev ? Math.round(dev.percentage * 100) : -1
    readonly property bool charging: dev ? dev.state === UPowerDeviceState.Charging : false
    readonly property bool full: dev ? dev.state === UPowerDeviceState.FullyCharged : false

    function fmt(secs) {
        if (!secs || secs <= 0)
            return "";
        const h = Math.floor(secs / 3600);
        const m = Math.round((secs % 3600) / 60);
        return h > 0 ? h + " h " + m + " min" : m + " min";
    }

    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: Net.refreshProfile()

    SetGroup {
        Rectangle {
            width: parent.width
            height: 150
            radius: 22
            color: Theme.tint(0.07)

            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -14
                text: page.pct >= 0 ? page.pct + "%" : "--"
                color: Theme.text
                font.pixelSize: 54
                font.weight: Font.Light
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 38
                text: page.full ? "Fully charged" : (page.charging ? "Charging" : "On battery")
                color: Theme.dim
                font.pixelSize: 16
            }
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 20
                height: 8
                radius: 4
                color: Theme.tint(0.14)

                Rectangle {
                    width: parent.width * Math.max(0, page.pct) / 100
                    height: parent.height
                    radius: 4
                    color: page.pct <= 15 && !page.charging ? "#ff5f5f" : Theme.accent
                }
            }
        }
        SetRow {
            visible: !!page.dev && page.fmt(page.charging ? page.dev.timeToFull : page.dev.timeToEmpty) !== ""
            title: page.charging ? "Time to full" : "Time remaining"
            subtitle: page.dev ? page.fmt(page.charging ? page.dev.timeToFull : page.dev.timeToEmpty) : ""
            tappable: false
        }
    }

    SetGroup {
        visible: Net.profile !== ""
        title: "Power mode"
        SetChips {
            options: ["Power saver", "Balanced", "Performance"]
            current: Math.max(0, ["power-saver", "balanced", "performance"].indexOf(Net.profile))
            onPicked: i => Net.setProfile(["power-saver", "balanced", "performance"][i])
        }
    }
}

// Bluetooth: power, scan, connect/disconnect, pair new devices. (Quickshell.Bluetooth / BlueZ)
import QtQuick
import Quickshell.Bluetooth
import qs.services
import qs.components

PanelFrame {
    id: p
    title: "Bluetooth"; icon: "bluetooth"
    readonly property var ad: Bluetooth.defaultAdapter
    // connected first, then paired, then the rest (only listed while scanning)
    readonly property var devs: {
        if (!ad) return [];
        const l = ad.devices.values.filter(d => d.name && (d.paired || d.connected || ad.discovering));
        return l.sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name));
    }
    Component.onDestruction: { if (ad && ad.discovering) ad.discovering = false }

    Column {
        anchors.fill: parent; spacing: 8
        Text { visible: !p.ad; text: "No Bluetooth adapter found"; color: "#99ffffff"; font.pixelSize: 13 }
        Row {
            visible: p.ad !== null; spacing: 10
            Toggle { checked: p.ad ? p.ad.enabled : false; onToggled: p.ad.enabled = !p.ad.enabled }
            Text { text: p.ad && p.ad.enabled ? "On" : "Off"; color: "white"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            PillButton { visible: p.ad && p.ad.enabled; label: p.ad && p.ad.discovering ? "Stop scan" : "Scan"; icon: "bluetooth_searching"
                         onClicked: p.ad.discovering = !p.ad.discovering }
        }
        Flickable {
            width: parent.width; height: parent.height - 44; clip: true; contentHeight: dl.height; boundsBehavior: Flickable.StopAtBounds
            Column {
                id: dl; width: parent.width; spacing: 3
                Repeater {
                    model: p.ad && p.ad.enabled ? p.devs : []
                    Rectangle {
                        required property var modelData
                        width: dl.width; height: 44; radius: 12
                        color: dma.containsMouse ? "#22ffffff" : (modelData.connected ? "#18ffffff" : "transparent")
                        Icon { id: bi; anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                               name: modelData.connected ? "bluetooth_connected" : "bluetooth"; size: 20
                               color: modelData.connected ? Theme.primary : "white" }
                        Column {
                            anchors { left: bi.right; leftMargin: 10; right: bst.left; verticalCenter: parent.verticalCenter }
                            Text { width: parent.width; elide: Text.ElideRight; text: modelData.name; font.pixelSize: 13
                                   color: modelData.connected ? Theme.primary : "white"; font.weight: modelData.connected ? Font.DemiBold : Font.Normal }
                            Text { visible: modelData.batteryAvailable; color: "#99ffffff"; font.pixelSize: 11
                                   text: "Battery " + Math.round(modelData.battery * 100) + "%" }
                        }
                        Text { id: bst; anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                               font.pixelSize: 11; color: "#99ffffff"
                               text: modelData.connected ? "connected" : (modelData.paired ? "paired" : "tap to pair") }
                        MouseArea {
                            id: dma; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                if (modelData.connected) modelData.connected = false;
                                else if (modelData.paired) modelData.connected = true;
                                else { modelData.trusted = true; modelData.pair() }
                            }
                        }
                    }
                }
                Text { visible: p.ad && p.ad.enabled && p.devs.length === 0; color: "#77ffffff"; font.pixelSize: 12
                       text: "No paired devices. Press Scan." }
            }
        }
    }
}

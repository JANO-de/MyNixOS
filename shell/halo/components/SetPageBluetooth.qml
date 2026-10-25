import QtQuick
import qs.services

// Settings > Bluetooth: switch, 8 s discovery, device list (tap = connect/disconnect, unpaired = pair first).
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: {
        System.refresh();
        Net.refreshBt();
    }

    SetGroup {
        SetRow {
            glyph: "✧"
            title: "Bluetooth"
            subtitle: System.bluetooth ? "On" : "Off"
            onClicked: System.toggleBluetooth()

            SetSwitch {
                checked: System.bluetooth
                onToggled: System.toggleBluetooth()
            }
        }
    }

    SetGroup {
        visible: System.bluetooth
        title: "Devices"

        Repeater {
            model: Net.devices

            SetRow {
                required property var modelData

                title: modelData.name
                subtitle: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "Not paired - tap to pair")
                onClicked: Net.toggleDevice(modelData)

                SetButton {
                    visible: modelData.paired
                    text: "Forget"
                    onClicked: Net.forgetDevice(modelData)
                }
            }
        }

        SetRow {
            glyph: "⟳"
            title: "Search for devices"
            subtitle: Net.btBusy ? "Searching..." : "Scans for 8 seconds"
            onClicked: Net.scanBt()
        }
    }
}

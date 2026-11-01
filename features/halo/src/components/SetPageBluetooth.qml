import QtQuick
import qs.services

// Settings > Connected devices > Bluetooth (AOSP: Use Bluetooth, paired devices, available devices, pair new device).
Column {
    id: page

    readonly property var paired: Net.devices.filter(d => d.paired)
    readonly property var avail: Net.devices.filter(d => !d.paired)

    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: {
        System.refresh();
        Net.refreshBt();
    }

    SetGroup {
        SetRow {
            glyph: "✧"
            title: "Use Bluetooth"
            subtitle: System.bluetooth ? "On" : "Off"
            onClicked: System.toggleBluetooth()

            SetSwitch {
                checked: System.bluetooth
                onToggled: System.toggleBluetooth()
            }
        }
    }

    SetGroup {
        visible: System.bluetooth && page.paired.length > 0
        title: "Paired devices"
        Repeater {
            model: page.paired
            SetRow {
                required property var modelData
                title: modelData.name
                subtitle: modelData.connected ? "Connected" : "Paired - tap to connect"
                onClicked: Net.toggleDevice(modelData)
                SetButton { text: "Forget"; onClicked: Net.forgetDevice(modelData) }
            }
        }
    }

    SetGroup {
        visible: System.bluetooth
        title: "Available devices"
        Repeater {
            model: page.avail
            SetRow {
                required property var modelData
                title: modelData.name
                subtitle: "Tap to pair"
                onClicked: Net.toggleDevice(modelData)
            }
        }
        SetRow {
            glyph: "＋"
            title: "Pair new device"
            subtitle: Net.btBusy ? "Searching..." : "Scans for 8 seconds"
            onClicked: Net.scanBt()
        }
    }
}

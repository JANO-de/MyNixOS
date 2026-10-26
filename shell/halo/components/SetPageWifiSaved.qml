import QtQuick
import qs.services

// Subpage wifi/saved: every saved Wi-Fi profile (also those out of range), with Forget.
Column {
    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: Net.scanWifi()

    SetGroup {
        title: "Saved networks"
        Repeater {
            model: Net.savedWifi
            SetRow {
                required property string modelData
                title: modelData
                subtitle: modelData === System.wifiName ? "Connected" : "Saved"
                tappable: false
                SetButton { text: "Forget"; danger: true; onClicked: Net.forgetWifi(modelData) }
            }
        }
        SetRow {
            visible: Net.savedWifi.length === 0
            title: "No saved networks"
            tappable: false
        }
    }
}

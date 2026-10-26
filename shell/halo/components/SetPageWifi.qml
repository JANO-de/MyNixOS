import QtQuick
import qs.services

// Settings > Wi-Fi: switch, status and the network list (tap = connect; secured and unknown = password field).
Column {
    id: page

    property string sel: "" // ssid whose detail panel is open

    width: parent ? parent.width : 600
    spacing: 22

    function bars(s) {
        return s >= 75 ? "▂▄▆█" : (s >= 50 ? "▂▄▆" : (s >= 25 ? "▂▄" : "▂"));
    }

    Component.onCompleted: {
        System.refresh();
        Net.scanWifi();
    }

    SetGroup {
        SetRow {
            glyph: "≋"
            title: "Wi-Fi"
            subtitle: !System.wifi ? "Off" : (System.wifiName !== "" ? "Connected to " + System.wifiName : "Not connected")
            onClicked: System.toggleWifi()

            SetSwitch {
                checked: System.wifi
                onToggled: System.toggleWifi()
            }
        }
    }

    Text {
        visible: Net.status !== ""
        width: parent.width
        leftPadding: 8
        text: Net.status
        color: Theme.dim
        font.pixelSize: 14
        wrapMode: Text.WordWrap
    }

    SetGroup {
        visible: System.wifi
        title: "Networks"

        Repeater {
            model: Net.networks

            Column {
                id: net

                required property var modelData
                readonly property bool open: page.sel === modelData.ssid

                width: parent.width
                spacing: 3

                SetRow {
                    title: net.modelData.ssid
                    subtitle: net.modelData.active ? "Connected" : (net.modelData.saved ? "Saved" : (net.modelData.secured ? "Secured" : "Open"))
                    onClicked: {
                        if (net.modelData.active || (!net.modelData.saved && net.modelData.secured))
                            page.sel = net.open ? "" : net.modelData.ssid;
                        else
                            Net.connectWifi(net.modelData.ssid, "");
                    }

                    Row {
                        spacing: 12
                        SetButton {
                            visible: net.modelData.saved && !net.modelData.active
                            text: "Forget"
                            onClicked: Net.forgetWifi(net.modelData.ssid)
                        }
                        Text {
                            height: 36
                            verticalAlignment: Text.AlignVCenter
                            text: (net.modelData.secured ? "🔒 " : "") + page.bars(net.modelData.signal)
                            color: net.modelData.active ? Theme.accent : Theme.dim
                            font.pixelSize: 15
                        }
                    }
                }

                // Detail panel: disconnect/forget for the active network, password for a new secured one.
                Rectangle {
                    visible: net.open
                    width: parent.width
                    height: panel.height + 28
                    radius: 22
                    color: Theme.tint(0.05)

                    Column {
                        id: panel
                        x: 16
                        y: 14
                        width: parent.width - 32
                        spacing: 10

                        Row {
                            visible: net.modelData.active
                            spacing: 10
                            SetButton { text: "Disconnect"; onClicked: { Net.disconnectWifi(); page.sel = ""; } }
                            SetButton { text: "Forget"; danger: true; onClicked: { Net.forgetWifi(net.modelData.ssid); page.sel = ""; } }
                        }

                        Item {
                            visible: !net.modelData.active
                            width: parent.width
                            height: 48

                            SetInput {
                                id: pw
                                anchors.left: parent.left
                                anchors.right: go.left
                                anchors.rightMargin: 10
                                placeholder: "Password"
                                password: true
                                grab: net.open && !net.modelData.active
                                onAccepted: go.clicked()
                            }
                            SetButton {
                                id: go
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Connect"
                                accent: true
                                onClicked: {
                                    Net.connectWifi(net.modelData.ssid, pw.text);
                                    pw.text = "";
                                    page.sel = "";
                                }
                            }
                        }
                    }
                }
            }
        }

        SetRow {
            glyph: "⟳"
            title: "Scan for networks"
            subtitle: Net.wifiBusy ? "Scanning..." : (Net.networks.length + " found")
            onClicked: Net.scanWifi()
        }
    }
}

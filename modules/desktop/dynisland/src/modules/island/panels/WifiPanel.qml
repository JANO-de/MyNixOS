// Wi-Fi: on/off, scan, connect (asks for the password of new secured networks), disconnect.
// Uses nmcli (NetworkManager). Known networks connect without a password.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

PanelFrame {
    id: p
    title: "Wi-Fi"; icon: "wifi"
    property var nets: []
    property bool radioOn: true
    property string busy: ""          // ssid being connected
    property string askFor: ""        // ssid that needs a password
    property string message: ""
    onAskForChanged: UiState.panelKeys = askFor !== ""
    Component.onDestruction: UiState.panelKeys = false

    function refresh() { list.running = true }
    function scan() { rescan.running = true }
    function connectTo(ssid, pw) {
        busy = ssid; message = "";
        conn.command = pw ? ["nmcli", "dev", "wifi", "connect", ssid, "password", pw] : ["nmcli", "dev", "wifi", "connect", ssid];
        conn.ssid = ssid; conn.usedPw = !!pw; conn.running = true;
    }

    Component.onCompleted: { radio.running = true; refresh(); scan() }

    Process { id: radio; command: ["nmcli", "radio", "wifi"]; stdout: StdioCollector { onStreamFinished: p.radioOn = text.trim() === "enabled" } }
    Process { id: setRadio; onExited: { radio.running = true; p.scan() } }
    Process { id: rescan; command: ["nmcli", "dev", "wifi", "rescan"]; onExited: p.refresh() }
    Process {
        id: list
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}, out = [];
                text.split("\n").forEach(l => {
                    const a = l.split(":");
                    if (a.length < 4) return;
                    const ssid = a.slice(3).join(":").replace(/\\:/g, ":");
                    if (!ssid || seen[ssid] !== undefined) return;
                    seen[ssid] = true;
                    out.push({ ssid: ssid, signal: Number(a[1]) || 0, secure: a[2].trim() !== "", active: a[0] === "*" });
                });
                out.sort((x, y) => (y.active - x.active) || (y.signal - x.signal));
                p.nets = out;
            }
        }
    }
    Process {
        id: conn
        property string ssid: ""
        property bool usedPw: false
        stderr: StdioCollector { id: connErr }
        onExited: code => {
            p.busy = "";
            if (code === 0) { p.askFor = ""; p.message = "Connected to " + ssid }
            else {
                const net = p.nets.find(n => n.ssid === ssid);
                if (!usedPw && net && net.secure) p.askFor = ssid;     // new secured network: ask for the password
                else p.message = usedPw ? "Wrong password?" : "Could not connect";
            }
            p.refresh();
        }
    }
    Process { id: disc; onExited: p.refresh() }

    Column {
        anchors.fill: parent; spacing: 8
        Row {
            spacing: 10
            Toggle { checked: p.radioOn; onToggled: { setRadio.command = ["nmcli", "radio", "wifi", p.radioOn ? "off" : "on"]; setRadio.running = true } }
            Text { text: p.radioOn ? "On" : "Off"; color: "white"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            PillButton { label: "Scan"; icon: "refresh"; onClicked: p.scan(); visible: p.radioOn }
        }
        Text { visible: p.message !== ""; text: p.message; color: Theme.primary; font.pixelSize: 12 }

        // password prompt
        Row {
            visible: p.askFor !== ""; spacing: 8; width: parent.width
            Rectangle {
                width: parent.width - 96; height: 34; radius: 17; color: "#18ffffff"
                TextInput {
                    id: pw; anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password; color: "white"; font.pixelSize: 13; clip: true
                    onAccepted: p.connectTo(p.askFor, text)
                    Text { visible: pw.text === ""; anchors.verticalCenter: parent.verticalCenter; text: "Password for " + p.askFor; color: "#77ffffff"; font.pixelSize: 13 }
                }
                MouseArea { anchors.fill: parent; z: -1; onClicked: pw.forceActiveFocus() }
            }
            PillButton { label: "Join"; filled: true; onClicked: p.connectTo(p.askFor, pw.text) }
        }

        Flickable {
            width: parent.width; height: parent.height - 80; clip: true; contentHeight: nl.height; boundsBehavior: Flickable.StopAtBounds
            Column {
                id: nl; width: parent.width; spacing: 3
                Repeater {
                    model: p.radioOn ? p.nets : []
                    Rectangle {
                        required property var modelData
                        width: nl.width; height: 38; radius: 12
                        color: nma.containsMouse ? "#22ffffff" : (modelData.active ? "#18ffffff" : "transparent")
                        Icon { id: ico; anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                               name: modelData.signal > 66 ? "network_wifi" : (modelData.signal > 33 ? "network_wifi_3_bar" : "network_wifi_1_bar"); size: 20
                               color: modelData.active ? Theme.primary : "white" }
                        Text { anchors { left: ico.right; leftMargin: 10; right: lock.left; verticalCenter: parent.verticalCenter }
                               elide: Text.ElideRight; text: modelData.ssid; font.pixelSize: 13
                               color: modelData.active ? Theme.primary : "white"; font.weight: modelData.active ? Font.DemiBold : Font.Normal }
                        Icon { id: lock; visible: modelData.secure; name: "lock"; size: 15; color: "#88ffffff"
                               anchors { right: st.left; rightMargin: 8; verticalCenter: parent.verticalCenter } }
                        Text { id: st; anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                               font.pixelSize: 11; color: "#99ffffff"
                               text: p.busy === modelData.ssid ? "connecting..." : (modelData.active ? "connected" : "") }
                        MouseArea {
                            id: nma; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                if (modelData.active) { disc.command = ["nmcli", "connection", "down", "id", modelData.ssid]; disc.running = true }
                                else p.connectTo(modelData.ssid, "")
                            }
                        }
                    }
                }
                Text { visible: p.radioOn && p.nets.length === 0; text: "No networks found"; color: "#77ffffff"; font.pixelSize: 12 }
            }
        }
    }
}

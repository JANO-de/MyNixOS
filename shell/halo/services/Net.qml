pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wi-Fi and Bluetooth lists + power profile for the Settings app (nmcli, bluetoothctl, powerprofilesctl).
// The on/off switches themselves live in System.qml.
Singleton {
    id: root

    property var networks: [] // { ssid, signal, secured, active, saved }
    property var devices: [] // { mac, name, connected, paired }
    property string status: ""
    property bool wifiBusy: false
    property bool btBusy: false
    property string profile: "" // "" = powerprofilesctl not available

    // nmcli -t escapes ":" and "\" with a backslash.
    function splitNm(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line.charAt(i);
            if (c === "\\" && i + 1 < line.length) {
                cur += line.charAt(i + 1);
                i++;
            } else if (c === ":") {
                out.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        out.push(cur);
        return out;
    }

    function isSaved(ssid) {
        for (const n of networks)
            if (n.ssid === ssid)
                return n.saved;
        return false;
    }

    // ---- Wi-Fi --------------------------------------------------------------------------------
    function scanWifi() {
        if (wifiProc.running)
            return;
        wifiBusy = true;
        wifiProc.running = true;
    }

    function connectWifi(ssid, password) {
        if (connProc.running)
            return;
        status = "Connecting to " + ssid + "...";
        connProc.ssid = ssid;
        if (password !== "")
            connProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        else if (isSaved(ssid))
            connProc.command = ["nmcli", "con", "up", "id", ssid];
        else
            connProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        connProc.running = true;
    }

    function disconnectWifi() {
        Quickshell.execDetached(["sh", "-c", "nmcli dev disconnect \"$(nmcli -t -f DEVICE,TYPE dev | awk -F: '$2==\"wifi\"{print $1; exit}')\""]);
        rescan.restart();
    }

    function forgetWifi(ssid) {
        Quickshell.execDetached(["nmcli", "con", "delete", "id", ssid]);
        rescan.restart();
    }

    Timer {
        id: rescan
        interval: 1500
        onTriggered: {
            root.scanWifi();
            System.refresh();
        }
    }

    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE con show | grep ':802-11-wireless$' | sed 's/:802-11-wireless$//; s/^/S:/'; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list | sed 's/^/W:/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = {};
                const best = {};
                for (const line of text.split("\n")) {
                    if (line.indexOf("S:") === 0) {
                        saved[root.splitNm(line.substring(2))[0]] = true;
                    } else if (line.indexOf("W:") === 0) {
                        const f = root.splitNm(line.substring(2));
                        if (f.length < 4 || f[1] === "")
                            continue;
                        const sig = parseInt(f[2]) || 0;
                        const n = { ssid: f[1], signal: sig, secured: f[3] !== "" && f[3] !== "--", active: f[0] === "*", saved: false };
                        const o = best[n.ssid];
                        if (!o || n.active || (!o.active && sig > o.signal))
                            best[n.ssid] = n;
                    }
                }
                const list = Object.keys(best).map(k => {
                    const n = best[k];
                    n.saved = !!saved[k];
                    return n;
                });
                list.sort((a, b) => ((b.active ? 1 : 0) - (a.active ? 1 : 0)) || (b.signal - a.signal));
                root.networks = list;
                root.wifiBusy = false;
            }
        }
        onExited: root.wifiBusy = false
    }

    Process {
        id: connProc
        property string ssid: ""
        onExited: code => {
            root.status = code === 0 ? "Connected to " + ssid : "Could not connect to " + ssid;
            root.scanWifi();
            System.refresh();
        }
    }

    // ---- Bluetooth ----------------------------------------------------------------------------
    function refreshBt() {
        if (btProc.running)
            return;
        btBusy = true;
        btProc.running = true;
    }

    function scanBt() {
        if (!btScan.running)
            btScan.running = true;
    }

    function toggleDevice(d) {
        if (btAct.running)
            return;
        if (d.connected)
            btAct.command = ["bluetoothctl", "disconnect", d.mac];
        else if (d.paired)
            btAct.command = ["bluetoothctl", "connect", d.mac];
        else
            btAct.command = ["sh", "-c", "bluetoothctl pair \"$1\" && bluetoothctl trust \"$1\" && bluetoothctl connect \"$1\"", "halo-bt", d.mac];
        btAct.running = true;
    }

    function forgetDevice(d) {
        Quickshell.execDetached(["bluetoothctl", "remove", d.mac]);
        btPoll.restart();
    }

    Process {
        id: btProc
        command: ["sh", "-c", "bluetoothctl devices | while read -r _ mac name; do i=$(bluetoothctl info \"$mac\" 2>/dev/null </dev/null); c=0; p=0; echo \"$i\" | grep -q 'Connected: yes' && c=1; echo \"$i\" | grep -q 'Paired: yes' && p=1; echo \"$mac|$c|$p|$name\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const f = line.split("|");
                    if (f.length < 4 || f[0] === "")
                        continue;
                    out.push({ mac: f[0], connected: f[1] === "1", paired: f[2] === "1", name: f.slice(3).join("|") });
                }
                out.sort((a, b) => ((b.connected ? 1 : 0) - (a.connected ? 1 : 0)) || ((b.paired ? 1 : 0) - (a.paired ? 1 : 0)) || a.name.localeCompare(b.name));
                root.devices = out;
                root.btBusy = false;
            }
        }
        onExited: root.btBusy = false
    }

    // 8 s of discovery, refreshing the list every 2 s meanwhile.
    Process {
        id: btScan
        command: ["bluetoothctl", "--timeout", "8", "scan", "on"]
        onRunningChanged: if (!running) root.refreshBt()
    }

    Timer {
        id: btPoll
        interval: 2000
        repeat: btScan.running
        running: btScan.running
        onTriggered: root.refreshBt()
    }

    Process {
        id: btAct
        onRunningChanged: if (!running) root.refreshBt()
    }

    // ---- Power profile -------------------------------------------------------------------------
    function refreshProfile() {
        profProc.running = true;
    }

    function setProfile(p) {
        profile = p;
        Quickshell.execDetached(["powerprofilesctl", "set", p]);
    }

    Process {
        id: profProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: root.profile = text.trim()
        }
    }
}

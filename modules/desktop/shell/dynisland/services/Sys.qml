// =============================================================================
//  Sys — quick settings: wifi (nmcli), bluetooth (BlueZ), backlight.
//  Polling runs only while `watching` is true (island sets it when expanded).
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.config
import qs.services

Singleton {
    id: root
    property bool watching: false

    // ---- Wi-Fi
    property bool wifiOn: false
    property string wifiName: ""
    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiOn ? "off" : "on"]);
        wifiOn = !wifiOn;
    }

    // ---- Bluetooth
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property bool btOn: bt ? bt.enabled : false
    function toggleBt() { if (bt) bt.enabled = !bt.enabled }

    // ---- Brightness 0..1 (hasBacklight=false on desktops -> slider hidden)
    property real brightness: 0
    property bool hasBacklight: false
    function setBrightness(v) {
        brightness = v;
        Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set", Math.round(v * 100) + "%"]);
        Osd.show("brightness", v);
    }

    // ---- Power actions (commands are in Config.system)
    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

    Timer {
        interval: 3000; repeat: true; triggeredOnStart: true; running: root.watching
        onTriggered: { wifiP.running = true; connP.running = true; briP.running = true }
    }
    Process {
        id: wifiP; command: ["nmcli", "-t", "-f", "WIFI", "g"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: connP; command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n").find(x => x.indexOf("wireless") >= 0);
                root.wifiName = l ? l.split(":")[0] : "";
            }
        }
    }
    Process {
        id: briP; command: ["brightnessctl", "-c", "backlight", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",");
                root.hasBacklight = p.length >= 4;
                if (root.hasBacklight) root.brightness = parseInt(p[3]) / 100;
            }
        }
    }
}

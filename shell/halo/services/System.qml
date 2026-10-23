pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Quick-settings state: brightness, volume, Wi-Fi, Bluetooth.
// Polled by the shade while it is open (refresh()); setters update the UI at once.
Singleton {
    id: root

    property real brightness: 0.5
    property real volume: 0.5
    property bool muted: false
    property bool wifi: false
    property string wifiName: ""
    property bool bluetooth: false

    function refresh() {
        brightnessProc.running = true;
        volumeProc.running = true;
        wifiProc.running = true;
        btProc.running = true;
    }

    function clamp(v) {
        return Math.max(0, Math.min(1, v));
    }

    function setBrightness(v) {
        brightness = clamp(v);
        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.max(1, Math.round(brightness * 100)) + "%"]);
    }

    function setVolume(v) {
        volume = clamp(v);
        muted = false;
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"]);
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", volume.toFixed(2)]);
    }

    function toggleWifi() {
        wifi = !wifi;
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifi ? "on" : "off"]);
    }

    function toggleBluetooth() {
        bluetooth = !bluetooth;
        Quickshell.execDetached(["bluetoothctl", "power", bluetooth ? "on" : "off"]);
    }

    Process {
        id: brightnessProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // device,class,current,percent%,max
                const f = text.trim().split(",");
                if (f.length >= 4) {
                    const p = parseInt(f[3]);
                    if (!isNaN(p))
                        root.brightness = p / 100;
                }
            }
        }
    }

    Process {
        id: volumeProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                // "Volume: 0.45" or "Volume: 0.45 [MUTED]"
                const m = text.match(/Volume:\s*([0-9.]+)/);
                if (m)
                    root.volume = root.clamp(parseFloat(m[1]));
                root.muted = text.indexOf("[MUTED]") >= 0;
            }
        }
    }

    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.wifi = lines[0] === "enabled";
                root.wifiName = (lines.length > 1 && lines[1].indexOf("yes:") === 0) ? lines[1].substring(4) : "";
            }
        }
    }

    Process {
        id: btProc
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -i 'Powered:'"]
        stdout: StdioCollector {
            onStreamFinished: root.bluetooth = text.indexOf("yes") >= 0
        }
    }
}

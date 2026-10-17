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

    // ---- Night light. On Wayland `gammastep -O <temp>` keeps running to hold the tint,
    // so it is run as a managed Process: running=false sends SIGTERM and gammastep restores the screen.
    property bool nightLight: false
    Process {
        id: nlProc
        command: ["gammastep", "-O", String(Config.system.nightLightTemp)]
        stderr: SplitParser { onRead: l => console.warn("night light:", l) }
        onRunningChanged: if (!running && root.nightLight) root.nightLight = false   // died/failed -> button shows off
    }
    function toggleNightLight() {
        if (nightLight) { nightLight = false; nlProc.running = false; Quickshell.execDetached(["gammastep", "-x"]) }
        else { nightLight = true; nlProc.running = true }
    }

    // ---- Color picker (hyprpicker): click a pixel, the value is copied and shown as an activity
    property string lastColor: ""
    property var colorHistory: []
    Process {
        id: pickProc
        command: ["hyprpicker", "-a", "-f", Config.system.colorFormat]
        stdout: SplitParser { onRead: l => {
            const c = l.trim(); if (c === "") return;
            root.lastColor = c;
            root.colorHistory = [c].concat(root.colorHistory.filter(x => x !== c)).slice(0, 10);
            Activities.push("color", c + " copied", "colorize", 1, c.charAt(0) === "#" ? c : "#9e9e9e", 4)
        } }
    }
    function pickColor() { pickProc.running = false; pickProc.running = true }

    // ---- Idle inhibit ("keep awake"): holds a systemd-inhibit process while on
    property bool inhibit: false
    Process { id: inhibitProc; command: ["systemd-inhibit", "--what=idle:sleep", "--who=dynisland", "--why=user requested", "sleep", "infinity"] }
    function toggleInhibit() { inhibit = !inhibit; inhibitProc.running = inhibit }

    // ---- Screen recording (wf-recorder; toggled on/off, saved like screenshots)
    property bool recording: false
    property string recordFile: ""
    function toggleRecording() {
        if (recording) { Quickshell.execDetached(["pkill", "-INT", "-f", "wf-recorder"]); recording = false; Activities.push("record", "Recording saved", "movie", 1, "#4caf50", 3) }
        else {
            const dir = Config.system.recordDir;
            recordFile = dir + "/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".mp4";
            Quickshell.execDetached(["sh", "-c", "mkdir -p '" + dir + "' && g=\"$(slurp)\" && [ -n \"$g\" ] && setsid wf-recorder -g \"$g\" -f '" + recordFile + "' >/dev/null 2>&1 &"]);
            recording = true;
            Activities.push("record", "Recording…", "fiber_manual_record", -1, "#c0392b", 0);
        }
    }

    // ---- Focus mode: DND + hide dock/desktop widgets + dim wallpaper, one toggle
    property bool focusMode: false
    property real savedDim: 0
    function toggleFocus() {
        focusMode = !focusMode;
        Notifs.dnd = focusMode;
        if (focusMode) { savedDim = Config.appearance.wallpaperDim; Config.appearance.wallpaperDim = Math.max(savedDim, Config.system.focusDim) }
        else Config.appearance.wallpaperDim = savedDim;
    }

    // ---- Screenshot: launches detached (so it survives independent of Quickshell's
    // own process tracking, like a normal keybind would), then polls for the file.
    function screenshot() {
        const dir = Config.system.screenshotDir;
        const file = dir + "/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".png";
        const cmd = Config.system.screenshotCmd.replace(/%f/g, "'" + file + "'");
        Activities.push("screenshot", "Taking screenshot…", "photo_camera", -1, "", 0);
        Quickshell.execDetached(["sh", "-c", cmd]);
        shotWait.file = file; shotWait.tries = 0; shotWait.running = true;
    }
    Timer {
        id: shotWait
        property string file: ""; property int tries: 0
        interval: 500; repeat: true
        onTriggered: {
            tries++;
            if (tries > 40) { running = false; Activities.push("screenshot", "Screenshot failed (timed out)", "error", 1, "#c0392b", 4); return }
            shotCheck.command = ["test", "-e", file]; shotCheck.running = true;
        }
    }
    Process {
        id: shotCheck
        onExited: code => {
            if (code === 0) { shotWait.running = false; Activities.push("screenshot", "Screenshot saved", "photo_camera", 1, "#4caf50", 3)
                Quickshell.execDetached(["sh", "-c", "command -v wl-copy >/dev/null && wl-copy < '" + shotWait.file + "'"]) }
        }
    }

    // ---- Power actions (commands are in Config.system)
    function run(cmd) {
        if (cmd === "@lock") lock();
        else if (cmd === "@server") Server.toggle();
        else Quickshell.execDetached(["sh", "-c", cmd]);
    }
    // built-in lock screen, or the external command if turned off in Settings > System
    function lock() { if (Config.system.builtinLock) UiState.locked = true; else run(Config.system.lockCmd) }

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

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Control center registry: which tiles exist, which are enabled, in what order.
// Persisted to ~/.config/halo/controls.json.
Singleton {
    id: root

    readonly property var all: ["wifi", "bluetooth", "airplane", "dnd", "night", "rotation", "mode", "keyboard", "screenshot", "region", "record", "settings", "lock", "sleep", "restart", "poweroff"]
    readonly property var defaults: ["wifi", "bluetooth", "airplane", "dnd", "night", "rotation", "mode", "keyboard", "screenshot", "region", "record", "settings", "lock", "sleep", "restart", "poweroff"]

    property bool night: false
    property bool recording: false
    property string armed: "" // restart/poweroff: first tap arms, second tap runs (3 s)

    property alias model: enabledModel
    property int rev: 0
    readonly property var available: {
        rev;
        const used = [];
        for (let i = 0; i < enabledModel.count; i++)
            used.push(enabledModel.get(i).tid);
        return all.filter(t => used.indexOf(t) < 0);
    }

    readonly property string dir: Quickshell.env("HOME") + "/.config/halo"

    ListModel { id: enabledModel }

    function apply(raw) {
        let ids = defaults;
        try {
            const p = JSON.parse(raw);
            if (Array.isArray(p))
                ids = p.filter(t => all.indexOf(t) >= 0);
        } catch (e) {}
        enabledModel.clear();
        for (const t of ids)
            enabledModel.append({ tid: t });
        rev++;
    }

    function save() {
        const ids = [];
        for (let i = 0; i < enabledModel.count; i++)
            ids.push(enabledModel.get(i).tid);
        file.setText(JSON.stringify(ids));
        rev++;
    }

    function move(from, to) {
        enabledModel.move(from, to, 1);
        rev++;
    }

    function remove(index) {
        enabledModel.remove(index);
        save();
    }

    function add(tid) {
        enabledModel.append({ tid: tid });
        save();
    }

    function closesShade(tid) {
        return tid === "mode" || tid === "keyboard" || tid === "screenshot" || tid === "region" || tid === "lock" || tid === "settings" || tid === "sleep" || tid === "record" || (tid === "restart" || tid === "poweroff") && armed === "";
    }

    function info(tid) {
        switch (tid) {
        case "wifi":
            return { icon: "wifi", title: "Wi-Fi", sub: System.wifi ? (System.wifiName !== "" ? System.wifiName : "On") : "Off", active: System.wifi };
        case "bluetooth":
            return { icon: "bluetooth", title: "Bluetooth", sub: System.bluetooth ? "On" : "Off", active: System.bluetooth };
        case "airplane":
            return { icon: "airplane", title: "Airplane", sub: System.airplane ? "On" : "Off", active: System.airplane };
        case "dnd":
            return { icon: "moon", title: "Do not disturb", sub: Notifs.dnd ? "On" : "Off", active: Notifs.dnd };
        case "rotation":
            return { icon: "rotation", title: "Rotation", sub: System.rotationLocked ? "Locked" : "Auto", active: System.rotationLocked };
        case "mode":
            return { icon: Mode.tablet ? "tablet" : "monitor", title: Mode.tablet ? "Tablet" : "Desktop", sub: "Switch mode", active: Mode.tablet };
        case "keyboard":
            return { icon: "keyboard", title: "Keyboard", sub: Kbd.visible ? "Shown" : "Hidden", active: Kbd.visible };
        case "screenshot":
            return { icon: "screenshot", title: "Screenshot", sub: "Full screen", active: false };
        case "lock":
            return { icon: "lock", title: "Lock", sub: "Lock screen", active: false };
        case "night":
            return { icon: "sunset", title: "Night light", sub: night ? "3500 K" : "Off", active: night };
        case "region":
            return { icon: "region", title: "Screenshot area", sub: "Select a region", active: false };
        case "record":
            return { icon: "record", title: recording ? "Stop recording" : "Screen record", sub: recording ? "Recording now" : "Saves to Videos", active: recording };
        case "settings":
            return { icon: "gear", title: "Settings", sub: "Open Settings", active: false };
        case "sleep":
            return { icon: "sleep", title: "Sleep", sub: "Suspend", active: false };
        case "restart":
            return { icon: "restart", title: "Restart", sub: armed === "restart" ? "Tap again to confirm" : "Reboot device", active: armed === "restart" };
        case "poweroff":
            return { icon: "power", title: "Power off", sub: armed === "poweroff" ? "Tap again to confirm" : "Shut down", active: armed === "poweroff" };
        }
        return { icon: "", title: tid, sub: "", active: false };
    }

    function trigger(tid) {
        switch (tid) {
        case "wifi":
            System.toggleWifi();
            break;
        case "bluetooth":
            System.toggleBluetooth();
            break;
        case "airplane":
            System.toggleAirplane();
            break;
        case "dnd":
            Notifs.dnd = !Notifs.dnd;
            break;
        case "rotation":
            System.toggleRotationLock();
            break;
        case "mode":
            Quickshell.execDetached(["hyprctl", "eval", "set_mode(\"" + (Mode.tablet ? "desktop" : "tablet") + "\")"]);
            break;
        case "keyboard":
            Kbd.toggle();
            break;
        case "lock":
            Lock.lock();
            break;
        case "night":
            night = !night;
            if (night)
                Quickshell.execDetached(["hyprsunset", "-t", "3500"]);
            else
                Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
            break;
        case "region":
            Quickshell.execDetached(["sh", "-c", "sleep 0.4; g=$(slurp) || exit 0; mkdir -p ~/Pictures/Screenshots; f=~/Pictures/Screenshots/$(date +%F_%H-%M-%S).png; grim -g \"$g\" \"$f\" && wl-copy < \"$f\"; notify-send -t 2000 Screenshot \"Saved and copied\""]);
            break;
        case "record":
            recording = !recording;
            if (recording)
                Quickshell.execDetached(["sh", "-c", "mkdir -p ~/Videos/Screen\\ recordings; exec wf-recorder -f ~/Videos/Screen\\ recordings/recording-$(date +%Y%m%d-%H%M%S).mp4"]);
            else
                Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"]);
            break;
        case "settings":
            UI.openSettings();
            break;
        case "sleep":
            Quickshell.execDetached(["systemctl", "suspend"]);
            break;
        case "restart":
        case "poweroff":
            if (armed === tid) {
                armed = "";
                Quickshell.execDetached(["systemctl", tid === "restart" ? "reboot" : "poweroff"]);
            } else {
                armed = tid;
                armT.restart();
            }
            break;
        case "screenshot":
            Quickshell.execDetached(["sh", "-c", "sleep 0.6; mkdir -p ~/Pictures/Screenshots; f=~/Pictures/Screenshots/$(date +%F_%H-%M-%S).png; grim \"$f\" && notify-send -t 2000 Screenshot \"Saved to Pictures/Screenshots\""]);
            break;
        }
    }

    Timer {
        id: armT
        interval: 3000
        onTriggered: root.armed = ""
    }

    // Re-read night light / recording state (they can be started outside the shade).
    function refresh() {
        stateProc.running = true;
    }

    Process {
        id: stateProc
        command: ["sh", "-c", "echo $(pgrep -x hyprsunset >/dev/null && echo 1 || echo 0) $(pgrep -x wf-recorder >/dev/null && echo 1 || echo 0)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(" ");
                root.night = f[0] === "1";
                root.recording = f[1] === "1";
            }
        }
    }

    FileView {
        id: file
        path: root.dir + "/controls.json"
        atomicWrites: true
        onLoaded: root.apply(text())
        onLoadFailed: root.apply("")
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.dir])
}

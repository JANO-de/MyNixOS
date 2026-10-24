pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Control center registry: which tiles exist, which are enabled, in what order.
// Persisted to ~/.config/halo/controls.json.
Singleton {
    id: root

    readonly property var all: ["wifi", "bluetooth", "airplane", "dnd", "rotation", "mode", "keyboard", "screenshot", "lock"]
    readonly property var defaults: ["wifi", "bluetooth", "airplane", "dnd", "rotation", "mode", "keyboard", "screenshot", "lock"]

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
        return tid === "mode" || tid === "keyboard" || tid === "screenshot" || tid === "lock";
    }

    function info(tid) {
        switch (tid) {
        case "wifi":
            return { title: "Wi-Fi", sub: System.wifi ? (System.wifiName !== "" ? System.wifiName : "On") : "Off", active: System.wifi };
        case "bluetooth":
            return { title: "Bluetooth", sub: System.bluetooth ? "On" : "Off", active: System.bluetooth };
        case "airplane":
            return { title: "Airplane", sub: System.airplane ? "On" : "Off", active: System.airplane };
        case "dnd":
            return { title: "Do not disturb", sub: Notifs.dnd ? "On" : "Off", active: Notifs.dnd };
        case "rotation":
            return { title: "Rotation", sub: System.rotationLocked ? "Locked" : "Auto", active: System.rotationLocked };
        case "mode":
            return { title: Mode.tablet ? "Tablet" : "Desktop", sub: "Switch mode", active: Mode.tablet };
        case "keyboard":
            return { title: "Keyboard", sub: Kbd.visible ? "Shown" : "Hidden", active: Kbd.visible };
        case "screenshot":
            return { title: "Screenshot", sub: "Full screen", active: false };
        case "lock":
            return { title: "Lock", sub: "Lock screen", active: false };
        }
        return { title: tid, sub: "", active: false };
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
        case "screenshot":
            Quickshell.execDetached(["sh", "-c", "sleep 0.6; mkdir -p ~/Pictures/Screenshots; f=~/Pictures/Screenshots/$(date +%F_%H-%M-%S).png; grim \"$f\" && notify-send -t 2000 Screenshot \"Saved to Pictures/Screenshots\""]);
            break;
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

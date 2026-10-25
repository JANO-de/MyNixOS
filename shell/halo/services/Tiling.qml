pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

// Window placement for dock drags: Slide Over (floating strip at a screen edge) and Split View
// (two tiled windows side by side). Both go through `hyprctl --batch "dispatch ..."` on the ACTIVE
// window after a short delay, because the app has to be mapped and focused first.
//
// UNTESTED against the real compositor. Assumes classic hyprctl dispatchers (settiled, setfloating,
// resizeactive, moveactive, movewindow, movetoworkspace). If hyprland-mode.lua forces apps
// fullscreen/maximised in tablet mode, Split View needs a rule there as well.
Singleton {
    id: root

    readonly property int slideWidth: 420

    property var pending: null
    property string batch: ""

    function slideOver(item, side, screen) {
        pending = { kind: "slide", item: item, side: side, screen: screen };
        wsProc.running = true;
    }

    function splitView(item, side, screen) {
        const a = ToplevelManager.activeToplevel;
        // Nothing in front to split with, or it is already the front app: just open it.
        if (!a || item.windows.indexOf(a) >= 0) {
            Apps.activate(item);
            return;
        }
        pending = { kind: "split", item: item, side: side, screen: screen };
        wsProc.running = true;
    }

    // Workspace the user is on right now (first line of `hyprctl activeworkspace`: "workspace ID 3 (3) on monitor ...").
    Process {
        id: wsProc
        command: ["sh", "-c", "hyprctl activeworkspace | head -n1 | awk '{print $3}'"]
        stdout: StdioCollector {
            onStreamFinished: root.run(text.trim())
        }
    }

    function run(ws) {
        const p = pending;
        pending = null;
        if (!p)
            return;

        const front = ToplevelManager.activeToplevel;
        if (p.kind === "split" && front) {
            front.fullscreen = false;
            front.maximized = false;
        }

        // Bring the app to the current workspace (new windows open here; running ones may live elsewhere).
        const move = ws !== "" && /^[0-9]+$/.test(ws) ? "dispatch movetoworkspace " + ws + " ; " : "";
        let wait = 300;
        if (p.item.windows.length > 0) {
            p.item.windows[0].activate();
        } else if (p.item.entry) {
            p.item.entry.execute(); // not Home.launch: tablet mode would open a fresh workspace
            wait = 1300;
        } else {
            return;
        }

        if (p.kind === "split") {
            batch = move + "dispatch settiled ; dispatch movewindow " + (p.side === "left" ? "l" : "r");
        } else {
            const sw = p.screen ? p.screen.width : 1920;
            const sh = p.screen ? p.screen.height : 1080;
            const ox = p.screen ? p.screen.x : 0;
            const oy = p.screen ? p.screen.y : 0;
            const w = slideWidth;
            const h = Math.round(sh * 0.86);
            const x = ox + (p.side === "left" ? 16 : sw - w - 16);
            const y = oy + Math.round((sh - h) / 2);
            batch = move + "dispatch setfloating ; dispatch resizeactive exact " + w + " " + h + " ; dispatch moveactive exact " + x + " " + y;
        }
        delay.interval = wait;
        delay.restart();
    }

    Timer {
        id: delay
        onTriggered: Quickshell.execDetached(["hyprctl", "--batch", root.batch])
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

// Android-style Split Screen on Hyprland (0.55+, Lua config: hyprctl dispatch takes Lua dispatchers).
//
// Behaviour copied from Android (Launcher3 taskbar drag + WM Shell split screen):
//   - drag an app icon up: left / right half = drop target; the dropped app takes that half
//   - divider with a handle between the two apps: drag it, it snaps to 30/70, 50/50, 70/30;
//     dragging it to a screen edge dismisses that app (the other one goes full screen)
//   - Slide Over is NOT an Android feature and is no longer reachable from the dock
//
// Flow: remember the workspace and window list, open/activate the dropped app, wait (shell script)
// until its window exists, move it to the front workspace, tile it on the chosen side, resize to
// 50/50, then record the pair in $XDG_RUNTIME_DIR/halo-split.
// hyprctl output goes to `journalctl --user -t halo-tiling`.
Singleton {
    id: root

    // ---- active split ---------------------------------------------------------------------------
    property string splitL: "" // address (no 0x) of the left window
    property string splitR: ""
    property string splitWs: ""
    property real splitW: 0 // screen size the split was made on
    property real splitH: 0
    property real ratio: 0.5 // share of the width taken by the left window
    property bool splitAlive: false // both windows exist on splitWs
    property bool splitVisible: false // ... and that workspace is the one on screen
    property bool resizing: false // Android DividerView: not interactive while a resize runs

    readonly property real gapOut: Mode.tablet ? 6 : 10
    readonly property real gapIn: Mode.tablet ? 6 : 5
    // x of the gap between the two windows for a given ratio.
    function boundaryX(r) {
        return gapOut + r * (splitW - 2 * gapOut);
    }

    function hypr(batch) {
        Quickshell.execDetached(["sh", "-c", 'hyprctl --batch "$1" 2>&1 | systemd-cat -t halo-tiling', "sh", batch]);
    }

    function addr(a) {
        return 'window = "address:0x' + a + '"';
    }

    // Snap the left window to `r` (0.3 / 0.5 / 0.7).
    function applyRatio(r) {
        ratio = r;
        resizing = true;
        resizeTimer.restart();
        const wl = Math.round(r * (splitW - 2 * gapOut) - gapIn);
        hypr("dispatch hl.dsp.window.resize({ x = " + wl + ", y = " + Math.round(splitH - 2 * gapOut) + ", relative = false, " + addr(splitL) + " })");
    }

    // Dragged to an edge: that app leaves the split (own workspace), the other fills the screen.
    function dismiss(side) {
        const gone = side === "left" ? splitL : splitR;
        const stay = side === "left" ? splitR : splitL;
        hypr("dispatch hl.dsp.window.move({ workspace = \"empty\", follow = false, " + addr(gone) + " }) ; dispatch hl.dsp.focus({ " + addr(stay) + " })");
        clearSplit();
    }

    function clearSplit() {
        splitL = "";
        splitR = "";
        splitAlive = false;
        splitVisible = false;
        Quickshell.execDetached(["sh", "-c", ': > "$XDG_RUNTIME_DIR/halo-split"']);
        if (Mode.tablet)
            hypr('dispatch function() hl.config({ general = { layout = "monocle" } }) end');
    }

    Timer {
        id: resizeTimer
        interval: 400
        onTriggered: root.resizing = false
    }

    // ---- starting a split (dock drag) -----------------------------------------------------------
    property var pending: null

    function splitView(item, side, screen) {
        const a = ToplevelManager.activeToplevel;
        // Nothing in front to split with, or it is already the front app: just open it.
        if (!a || item.windows.indexOf(a) >= 0) {
            Apps.activate(item);
            return;
        }
        pending = { item: item, side: side, screen: screen, front: a.appId };
        infoProc.running = true;
    }

    // Line 1: workspace id of the FRONT APP's window (not the active workspace: from the dock that can be the
    // named home workspace, which is not numeric); falls back to the active workspace.
    // Line 2: addresses of all windows right now.
    Process {
        id: infoProc
        command: ["sh", "-c",
            "W=$(hyprctl clients | awk -v c=\"$1\" '/^Window /{w=\"\"} $1==\"workspace:\"{w=$2} $1==\"class:\" && $2==c {print w; exit}'); [ -n \"$W\" ] || W=$(hyprctl activeworkspace | head -n1 | awk '{print ($2==\"ID\")?$3:$2}'); echo \"$W\"; hyprctl clients | awk '/^Window /{printf \"%s \", $2}'; echo",
            "sh", root.pending ? root.pending.front : ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                root.run((l[0] || "").trim(), (l[1] || "").trim());
            }
        }
    }

    function run(ws, before) {
        const p = pending;
        pending = null;
        if (!p)
            return;

        const f = ToplevelManager.activeToplevel;
        if (f) {
            f.fullscreen = false;
            f.maximized = false;
        }

        const cls = p.item.windows.length > 0 ? p.item.windows[0].appId : "";
        if (p.item.windows.length > 0)
            p.item.windows[0].activate();
        else if (p.item.entry)
            p.item.entry.execute(); // not Home.launch: tablet mode would open a fresh workspace
        else
            return;

        // @W@ is replaced by the target window ("address:0x...") inside the script.
        const W = ' window = "@W@"';
        const sw = p.screen ? p.screen.width : 1920;
        const sh = p.screen ? p.screen.height : 1080;
        const move = /^[0-9]+$/.test(ws) ? "dispatch hl.dsp.window.move({ workspace = " + ws + ", follow = true," + W + " }) ; dispatch hl.dsp.focus({" + W + " }) ; " : "";
        // Tablet mode uses the monocle layout (one window visible): switch to dwindle so both show side by side.
        const batch = 'dispatch function() hl.config({ general = { layout = "dwindle" } }) end ; ' + move
            + 'dispatch hl.dsp.window.float({ action = "disable",' + W + ' }) ; '
            + 'dispatch hl.dsp.window.move({ direction = "' + p.side + '",' + W + ' })';
        // After the layout settled: 50/50.
        const wl = Math.round(0.5 * (sw - 2 * gapOut) - gapIn);
        const batch2 = "dispatch hl.dsp.window.resize({ x = " + wl + ", y = " + Math.round(sh - 2 * gapOut) + ", relative = false," + W + " })";

        // $1 class of the running app ("" = newly launched: first window not in $2), $3 batch, $4 batch2,
        // $5 workspace, $6 side, $7 screen w, $8 screen h.
        const script = '{ CL="$1"; BEFORE="$2"; N=""; i=0\n'
            + 'echo "ws=$5 side=$6 cls=$1"\n'
            + 'while [ $i -lt 60 ] && [ -z "$N" ]; do\n'
            + '  if [ -n "$CL" ]; then\n'
            + '    N=$(hyprctl clients | awk -v c="$CL" \'/^Window /{a=$2} $1=="class:" && $2==c {print a; exit}\')\n'
            + '  else\n'
            + '    for a in $(hyprctl clients | awk \'/^Window /{print $2}\'); do\n'
            + '      case " $BEFORE " in *" $a "*) ;; *) N=$a; break ;; esac\n'
            + '    done\n'
            + '  fi\n'
            + '  [ -n "$N" ] || { i=$((i+1)); sleep 0.1; }\n'
            + 'done\n'
            + '[ -n "$N" ] || { echo "target window not found"; exit 0; }\n'
            + 'echo "target $N"\n'
            + 'sleep 0.3\n'
            + 'hyprctl --batch "$(printf %s "$3" | sed "s/@W@/address:0x$N/g")" 2>&1\n'
            + 'sleep 0.5\n'
            + 'hyprctl --batch "$(printf %s "$4" | sed "s/@W@/address:0x$N/g")" 2>&1\n'
            + 'O=$(hyprctl clients | awk -v n="$N" -v w="$5" \'/^Window /{a=$2} $1=="workspace:" && $2==w && a!=n {print a; exit}\')\n'
            + 'if [ -n "$O" ]; then\n'
            + '  if [ "$6" = left ]; then L=$N; R=$O; else L=$O; R=$N; fi\n'
            + '  echo "$L $R $5 $7 $8" > "$XDG_RUNTIME_DIR/halo-split"\n'
            + '  echo "split $L | $R on $5"\n'
            + 'fi\n'
            + '} 2>&1 | systemd-cat -t halo-tiling';
        Quickshell.execDetached(["sh", "-c", script, "sh", cls, before, batch, batch2, ws, p.side, String(sw), String(sh)]);
    }

    // ---- state file -----------------------------------------------------------------------------
    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/halo-split"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const f = text().trim().split(/\s+/);
            if (f.length >= 5) {
                root.splitL = f[0];
                root.splitR = f[1];
                root.splitWs = f[2];
                root.splitW = parseFloat(f[3]);
                root.splitH = parseFloat(f[4]);
                root.ratio = 0.5;
                root.splitAlive = true;
                poll.running = true;
            } else {
                root.splitAlive = false;
                root.splitVisible = false;
            }
        }
        onLoadFailed: {
            root.splitAlive = false;
            root.splitVisible = false;
        }
    }

    // While a split exists: are both windows still on the split workspace, and is it the one on screen?
    Process {
        id: poll
        command: ["sh", "-c",
            "hyprctl clients | awk -v l=\"$1\" -v r=\"$2\" -v w=\"$3\" '/^Window /{a=$2} $1==\"workspace:\"{ws[a]=$2} END{print (ws[l]==w && ws[r]==w) ? \"OK\" : \"END\"}'; hyprctl activeworkspace | head -n1 | awk '{print ($2==\"ID\")?$3:$2}'",
            "sh", root.splitL, root.splitR, root.splitWs]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                if ((l[0] || "").trim() !== "OK") {
                    root.clearSplit();
                    return;
                }
                root.splitVisible = (l[1] || "").trim() === root.splitWs;
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.splitAlive
        onTriggered: if (!poll.running) poll.running = true
    }
}

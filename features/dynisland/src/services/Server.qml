// =============================================================================
//  Server — "Server mode": turns the PC into a headless-ish server.
//
//  ON  : llama.cpp unit started (if not running) · Tailscale up (+ SSH) · llama web UI
//        published on the tailnet · LEDs off (OpenRGB) · lock screen · monitors off ·
//        shell extras paused (cava, weather, calendar sync, dock, desktop widgets).
//        Fans are untouched (they keep running).
//  OFF : everything above is undone EXCEPT llama.cpp, which keeps running.
//
//  Open it from the island Power panel, Settings > Server, or:  dynisland ipc server toggle
//  State survives a shell restart through a marker file in $XDG_RUNTIME_DIR (cleared on reboot).
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

Singleton {
    id: root
    readonly property var cfg: Config.server
    readonly property string marker: Quickshell.env("XDG_RUNTIME_DIR") + "/dynisland-server"

    property bool active: false          // server mode is on
    property string loginUrl: ""         // set while Tailscale waits for a first-time login
    property string tsState: ""          // Tailscale BackendState: Running | Stopped | NeedsLogin ...
    property string tsIp: ""             // our tailnet IPv4
    property string tsName: ""           // MagicDNS name (host.tailnet.ts.net)
    property bool llamaUp: false         // llama.cpp /health says ok
    readonly property string status: !active ? "Off"
        : loginUrl !== "" ? "Waiting for Tailscale login"
        : tsState === "Running" ? "On · " + (tsName || tsIp)
        : "Starting…"

    function toggle() { active ? disable() : enable() }

    function enable() {
        if (active) return;
        active = true; loginUrl = "";
        Quickshell.execDetached(["touch", marker]);
        // keep llama.cpp up (polkit rule in default.nix allows this without a password)
        if (cfg.startLlama) Quickshell.execDetached(["systemctl", "start", cfg.llamaUnit + ".service"]);
        // Tailscale: set SSH flag, then bring it up (blocks until logged in the first time)
        if (cfg.tailscale) {
            up.command = ["sh", "-c", "tailscale set --ssh=" + cfg.ssh + " 2>/dev/null; exec tailscale up"];
            up.running = true;
        }
        if (cfg.ledsOff) Quickshell.execDetached(["sh", "-c", cfg.ledsOffCmd]);
        if (cfg.lockOnEnter) Sys.lock();
        if (cfg.screensOff) offT.restart();
    }

    function disable() {
        if (!active) return;
        active = false; loginUrl = "";
        offT.stop(); up.running = false;
        Quickshell.execDetached(["rm", "-f", marker]);
        if (cfg.screensOff) Wm.monitorsOn();
        if (cfg.ledsOff) Quickshell.execDetached(["sh", "-c", cfg.ledsOnCmd]);
        // llama.cpp is deliberately NOT stopped
        if (cfg.tailscale) Quickshell.execDetached(["sh", "-c", "tailscale serve reset; tailscale down"]);
        tsState = ""; tsIp = ""; tsName = "";
    }

    // monitors off a moment after locking (never while a first-time login URL is pending)
    Timer {
        id: offT; interval: 2500
        onTriggered: if (root.active && root.loginUrl === "") Wm.monitorsOff()
    }

    Process {
        id: up
        onExited: code => {
            if (!root.active) return;
            if (code === 0) {
                root.loginUrl = "";
                if (root.cfg.serve) Quickshell.execDetached(["tailscale", "serve", "--bg", String(root.cfg.port)]);
                statusP.running = true;
            }
        }
        // first-time login: tailscale prints "https://login.tailscale.com/a/..." on stderr
        stderr: SplitParser {
            onRead: line => {
                const m = line.match(/https:\/\/\S+/);
                if (m && root.loginUrl === "") {
                    root.loginUrl = m[0];
                    Quickshell.execDetached(["notify-send", "Tailscale login", m[0]]);
                    Quickshell.execDetached(["xdg-open", m[0]]);
                }
            }
        }
    }

    // while on: poll Tailscale + llama.cpp every 8 s
    Timer {
        interval: 8000; repeat: true; running: root.active; triggeredOnStart: true
        onTriggered: { statusP.running = true; llamaP.running = true }
    }
    Process {
        id: statusP; command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    root.tsState = j.BackendState || "";
                    const ips = j.Self && j.Self.TailscaleIPs;
                    root.tsIp = ips && ips.length ? ips[0] : "";
                    root.tsName = ((j.Self && j.Self.DNSName) || "").replace(/\.$/, "");
                } catch (e) { root.tsState = "" }
            }
        }
    }
    Process {
        id: llamaP; command: ["curl", "-s", "-m", "2", "http://127.0.0.1:" + root.cfg.port + "/health"]
        stdout: StdioCollector { onStreamFinished: root.llamaUp = text.indexOf("ok") >= 0 }
    }

    // restore the flag after a shell restart (does not re-run the enable steps)
    Process { running: true; command: ["test", "-e", root.marker]; onExited: code => { if (code === 0) root.active = true } }
}

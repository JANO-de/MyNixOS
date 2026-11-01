pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// Lock screen state + authentication.
//  - PIN: salted sha256 in ~/.config/halo/lock.json (create it with `halo-set-pin`).
//    A convenience lock, not strong protection: real protection is disk encryption + the password.
//  - Password: PAM service "halo" (security.pam.services.halo in halo.nix).
//  - 5 wrong tries -> cooldown (30 s, doubling, max 10 min).
//  - `$XDG_RUNTIME_DIR/halo-locked` survives a shell restart so a crash does not unlock the session.
Singleton {
    id: root

    property bool locked: false
    property string stage: "hero" // hero | pin | password
    property string error: ""
    property int failCount: 0
    property double cooldownUntil: 0
    property double now: Date.now()
    readonly property int cooldownSecs: Math.max(0, Math.ceil((cooldownUntil - now) / 1000))
    readonly property bool cooling: cooldownSecs > 0

    property string pinSalt: ""
    property string pinHash: ""
    property int pinLen: 0
    readonly property bool hasPin: pinHash !== "" && pinLen >= 4

    property string pendingPassword: ""
    readonly property string flagFile: Quickshell.env("XDG_RUNTIME_DIR") + "/halo-locked"

    signal wrong

    function lock() {
        if (locked)
            return;
        stage = "hero";
        error = "";
        locked = true;
        Quickshell.execDetached(["touch", flagFile]);
    }

    function unlock() {
        failCount = 0;
        error = "";
        locked = false;
        stage = "hero";
        Quickshell.execDetached(["rm", "-f", flagFile]);
    }

    function fail(msg) {
        failCount++;
        error = msg;
        wrong();
        if (failCount >= 5) {
            const secs = Math.min(600, 30 * Math.pow(2, failCount - 5));
            cooldownUntil = Date.now() + secs * 1000;
            now = Date.now();
        }
    }

    function submitPin(pin) {
        if (cooling || !hasPin)
            return;
        hasher.environment = ({ HALO_SALT: pinSalt, HALO_PIN: pin });
        hasher.running = true;
    }

    function submitPassword(pw) {
        if (cooling || pw === "")
            return;
        pendingPassword = pw;
        pam.start();
    }

    Timer {
        interval: 500
        repeat: true
        running: root.locked && root.cooldownUntil > root.now
        onTriggered: root.now = Date.now()
    }

    Process {
        id: hasher
        command: ["sh", "-c", "printf '%s%s' \"$HALO_SALT\" \"$HALO_PIN\" | sha256sum | cut -d' ' -f1"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === root.pinHash)
                    root.unlock();
                else
                    root.fail("Wrong passcode");
            }
        }
    }

    PamContext {
        id: pam
        config: "halo"
        onPamMessage: {
            if (responseRequired)
                respond(root.pendingPassword);
        }
        onCompleted: result => {
            root.pendingPassword = "";
            if (result === PamResult.Success)
                root.unlock();
            else
                root.fail("Wrong password");
        }
        onError: {
            root.pendingPassword = "";
            root.fail("Authentication error");
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/halo/lock.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const p = JSON.parse(text());
                root.pinSalt = p.salt || "";
                root.pinHash = p.hash || "";
                root.pinLen = p.len || 0;
            } catch (e) {}
        }
        onLoadFailed: {
            root.pinSalt = "";
            root.pinHash = "";
            root.pinLen = 0;
        }
    }

    // After a shell restart: stay locked if we were locked.
    Process {
        id: relock
        command: ["test", "-e", root.flagFile]
        onExited: exitCode => {
            if (exitCode === 0)
                root.locked = true;
        }
    }

    // Lock before suspend (logind PrepareForSleep).
    Process {
        running: true
        command: ["dbus-monitor", "--system", "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("boolean true") >= 0)
                    root.lock();
            }
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void { root.lock(); }
    }

    Component.onCompleted: relock.running = true
}

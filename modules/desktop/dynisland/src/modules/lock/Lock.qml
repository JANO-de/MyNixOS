// =============================================================================
//  Lock — session lock (ext-session-lock-v1) with PAM password check.
//
//  HOW IT WORKS
//   * UiState.locked = true  -> WlSessionLock asks niri to lock the session.
//     niri then HIDES everything else; only the surfaces we draw are visible.
//   * One WlSessionLockSurface (LockSurface.qml) is created per monitor.
//   * The password goes to PAM (PamContext). Success -> UiState.locked = false.
//   * If this shell crashes while locked, niri KEEPS the screen locked (safe).
//
//  TRIGGER:  lock button / power panel, or from a keybind:
//    spawn "qs" "-c" "dynisland" "ipc" "call" "lock" "lock"
//  EMERGENCY UNLOCK (from a TTY, only if Config.system.lockIpcUnlock is on):
//    qs -c dynisland ipc call lock unlock
// =============================================================================
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.config
import qs.services

Scope {
    id: root
    property bool busy: false        // PAM is checking
    property string error: ""        // message shown under the field
    property string pending: ""      // password waiting for PAM to ask for it
    signal failed()                  // surfaces shake on this

    function submit(pw) {
        if (busy || pw === "") return;
        pending = pw; error = ""; busy = true;
        pam.start();                 // PAM will ask for the password -> onPamMessage
    }

    PamContext {
        id: pam
        config: Config.system.pamService          // file in /etc/pam.d ("login" works on NixOS)
        onPamMessage: if (responseRequired) respond(root.pending)
        onCompleted: result => {
            root.busy = false; root.pending = "";
            if (result === PamResult.Success) { root.error = ""; UiState.locked = false }
            else {
                root.error = result === PamResult.MaxTries ? "Too many attempts" : "Wrong password";
                root.failed();
            }
        }
        onError: err => {
            root.busy = false; root.pending = "";
            root.error = "Authentication error";
            console.warn("Lock: pam error", err);
            root.failed();
        }
    }

    WlSessionLock {
        locked: UiState.locked
        // the default property is the component drawn once per monitor
        LockSurface { lock: root }
    }
}

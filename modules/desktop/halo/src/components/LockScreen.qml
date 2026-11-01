import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Session lock (ext-session-lock): one lock surface per screen. While locked the compositor
// shows only these surfaces. Auto-locks after 5 minutes idle.
Scope {
    WlSessionLock {
        locked: Lock.locked

        WlSessionLockSurface {
            color: "black"

            LockContent {
                anchors.fill: parent
            }
        }
    }

    IdleMonitor {
        timeout: 300
        onIsIdleChanged: if (isIdle) Lock.lock()
    }
}

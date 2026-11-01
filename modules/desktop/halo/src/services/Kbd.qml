pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// On-screen keyboard state, written by `kbd-toggle` to $XDG_RUNTIME_DIR/kbd-visible.
Singleton {
    id: root

    property bool visible: false
    property bool dismissed: false

    // Heights passed to wvkbd (-H portrait / -L landscape). Keep in sync with hyprland-touch.nix.
    readonly property int portraitHeight: 420
    readonly property int landscapeHeight: 300

    // Real height of the keyboard surface, written by `kbd-watch` (squeekboard). 0 = unknown.
    property int measuredHeight: 0

    function heightFor(screen) {
        if (measuredHeight > 0)
            return measuredHeight;
        return screen.width > screen.height ? landscapeHeight : portraitHeight;
    }

    // Always asks squeekboard (SetVisible true is idempotent); never trusts the mirrored `visible` flag,
    // which can be stale or 0.4 s behind. Calls closer than 250 ms are merged.
    property double lastShowAt: 0

    function show() {
        dismissed = false;
        const now = Date.now();
        if (now - lastShowAt < 250)
            return;
        lastShowAt = now;
        Quickshell.execDetached(["kbd-toggle", "show"]);
    }

    // Hide without raising the floating "show keyboard" button (tap outside a field, Settings closed).
    function hideQuiet() {
        Quickshell.execDetached(["kbd-toggle", "hide"]);
    }

    function hide() {
        root.dismissed = true;
        Quickshell.execDetached(["kbd-toggle", "hide"]);
    }

    function toggle() {
        Quickshell.execDetached(["kbd-toggle", "toggle"]);
    }

    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/kbd-visible"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.visible = text().trim() === "visible";
            if (root.visible)
                root.dismissed = false;
        }
        onLoadFailed: root.visible = false
    }

    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/kbd-height"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.measuredHeight = parseInt(text().trim()) || 0
        onLoadFailed: root.measuredHeight = 0
    }
}

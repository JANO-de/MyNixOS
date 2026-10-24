pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// On-screen keyboard state, written by `kbd-toggle` to $XDG_RUNTIME_DIR/kbd-visible.
Singleton {
    id: root

    property bool visible: false

    // Heights passed to wvkbd (-H portrait / -L landscape). Keep in sync with hyprland-touch.nix.
    readonly property int portraitHeight: 420
    readonly property int landscapeHeight: 300

    function heightFor(screen) {
        return screen.width > screen.height ? landscapeHeight : portraitHeight;
    }

    function hide() {
        Quickshell.execDetached(["kbd-toggle", "hide"]);
    }

    function toggle() {
        Quickshell.execDetached(["kbd-toggle", "toggle"]);
    }

    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/kbd-visible"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.visible = text().trim() === "visible"
        onLoadFailed: root.visible = false
    }
}

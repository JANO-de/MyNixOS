pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Mirrors $XDG_RUNTIME_DIR/hypr-mode, written by hyprland-mode.lua (set_mode).
Singleton {
    id: root

    property string mode: "desktop"
    readonly property bool tablet: mode === "tablet"

    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr-mode"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const m = text().trim();
            if (m === "tablet" || m === "desktop")
                root.mode = m;
        }
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Picture files for photo/sticker widgets: everything image-like under ~/Pictures (3 levels), newest first.
Singleton {
    id: root

    property var files: []
    readonly property var stickerGlyphs: ["\u2605", "\u2665", "\u2600", "\u263e", "\u273f", "\u266a", "\u2691", "\u263a", "\u2726", "\u2744", "\u2602", "\u26a1", "\u2708", "\u265b", "\u2618", "\u2714"]

    function rescan() {
        if (!scan.running)
            scan.running = true;
    }

    Process {
        id: scan
        command: ["sh", "-c", "mkdir -p \"$HOME/Pictures/Stickers\"; find -L \"$HOME/Pictures\" -maxdepth 3 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) -printf '%T@ %p\\n' 2>/dev/null | sort -rn | cut -d' ' -f2- | head -400"]
        stdout: StdioCollector {
            onStreamFinished: root.files = text.trim() === "" ? [] : text.trim().split("\n")
        }
    }

    Component.onCompleted: rescan()
}

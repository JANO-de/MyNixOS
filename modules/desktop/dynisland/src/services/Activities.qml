// =============================================================================
//  Activities — "Live Activities" (iOS 26 style): any script or app can push
//  a small live card (icon, label, progress) that takes over the island while
//  it runs, instead of a one-shot notification. Drive it over IPC:
//    qs -c dynisland ipc call activity push <id> <label> <icon> <progress 0..1 or -1> [color]
//    qs -c dynisland ipc call activity clear <id>
//  progress -1 = indeterminate (spinner dots instead of a bar). No expiresAt
//  means it stays until cleared; pass seconds to auto-clear.
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property var list: []   // [{id, label, icon, color, progress, expiresAt}], oldest first
    property int cursor: 0  // which one the compact pill is currently showing

    function push(id, label, icon, progress, color, ttlSeconds) {
        const item = { id: id, label: label || id, icon: icon || "bolt", progress: progress === undefined ? -1 : progress,
                        color: color || "", expiresAt: ttlSeconds > 0 ? Date.now() + ttlSeconds * 1000 : 0 };
        const i = root.list.findIndex(a => a.id === id);
        const next = root.list.slice();
        if (i >= 0) next[i] = item; else next.push(item);
        root.list = next;
    }
    function clear(id) { root.list = root.list.filter(a => a.id !== id); if (root.cursor >= root.list.length) root.cursor = 0 }
    function clearAll() { root.list = []; root.cursor = 0 }

    Timer {   // drop expired activities, and rotate which one the compact pill shows
        interval: 1000; repeat: true; running: true
        onTriggered: {
            const now = Date.now();
            if (root.list.some(a => a.expiresAt > 0 && a.expiresAt <= now))
                root.list = root.list.filter(a => a.expiresAt <= 0 || a.expiresAt > now);
            if (root.list.length > 1 && now % 4000 < 1000) root.cursor = (root.cursor + 1) % root.list.length;
            if (root.cursor >= root.list.length) root.cursor = 0;
        }
    }

    readonly property var current: list.length > 0 ? list[Math.min(cursor, list.length - 1)] : null
}

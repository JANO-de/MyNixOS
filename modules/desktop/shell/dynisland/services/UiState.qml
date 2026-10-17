// Shared UI state (what is open right now).
//   trayStack : open tray menu levels (empty = closed). Set by TrayStrip, shown by the island's "tray" mode.
//   trayEntries / trayHeight : entries of the current level + the island height needed to show them.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property bool settingsOpen: false
    property bool quickPage: false      // island's right column shows the quick toggles page (QuickPage.qml)
    property bool launcherOpen: false   // app drawer (modules/launcher)
    property bool locked: false         // session lock active (modules/lock)
    property bool islandPinned: false   // keep island expanded (IPC: island toggle)

    // desktop right-click menu (opened by the wallpaper window, drawn by DesktopMenu.qml)
    property bool deskMenuOpen: false
    property string deskMenuScreen: ""
    property real deskMenuX: 0
    property real deskMenuY: 0

    // island panels: "" | clock | weather | calendar | wifi | bluetooth | audio | power | history
    property string panel: ""
    property bool panelKeys: false      // a panel needs keyboard input (e.g. Wi-Fi password)
    function openPanel(name) { trayStack = []; panelKeys = false; panel = (panel === name ? "" : name) }
    function closePanel() { panel = ""; panelKeys = false }

    property var trayStack: []
    property string trayTitle: ""
    readonly property var trayEntries: trayOpener.children
    readonly property real trayHeight: {
        let h = 64;                                   // header + paddings
        const c = trayOpener.children;
        if (c) for (const e of c.values) h += e.isSeparator ? 9 : 32;
        return Math.min(440, h);
    }
    QsMenuOpener { id: trayOpener; menu: root.trayStack.length ? root.trayStack[root.trayStack.length - 1] : null }
}

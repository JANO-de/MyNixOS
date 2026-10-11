// =============================================================================
//  Notifs — freedesktop notification server. Stop the old python server first
//  (only one process can own org.freedesktop.Notifications).
//  The island shows Notifs.current for ~5s. Notifs.dnd silences popups.
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    property var current: null
    property bool dnd: false
    readonly property var list: server.trackedNotifications   // history

    function dismiss() { hide.stop(); current = null }

    Timer { id: hide; interval: 5000; onTriggered: root.current = null }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        imageSupported: true
        actionsSupported: true
        onNotification: n => {
            n.tracked = true;
            if (root.dnd) return;
            root.current = n;
            hide.interval = n.expireTimeout > 0 ? n.expireTimeout * 1000 : 5000;
            hide.restart();
        }
    }
}

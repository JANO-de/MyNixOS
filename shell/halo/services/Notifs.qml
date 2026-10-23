pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Halo is the notification daemon (org.freedesktop.Notifications).
Singleton {
    id: root

    property alias list: server.trackedNotifications
    property bool dnd: false
    readonly property int count: server.trackedNotifications.values.length

    // Latest banner as a plain copy (the notification object may be gone by the time it renders).
    property var banner: null

    function clearAll() {
        const all = server.trackedNotifications.values.slice();
        for (const n of all)
            n.dismiss();
    }

    function hideBanner() {
        banner = null;
    }

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: n => {
            n.tracked = true;
            if (!root.dnd) {
                root.banner = { app: n.appName, summary: n.summary, body: n.body };
                bannerTimer.restart();
            }
        }
    }

    Timer {
        id: bannerTimer
        interval: 5000
        onTriggered: root.banner = null
    }
}

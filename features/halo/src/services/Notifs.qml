pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Halo is the notification daemon (org.freedesktop.Notifications).
Singleton {
    id: root

    property alias list: server.trackedNotifications
    property bool dnd: false
    // Per-app switches (Settings > Notifications): app name -> true when muted; every app seen so far.
    property var muted: ({})
    property var seen: []
    readonly property string file: Quickshell.env("HOME") + "/.config/halo/notif-apps.json"

    function setMuted(app, on) {
        const m = Object.assign({}, muted);
        if (on)
            m[app] = true;
        else
            delete m[app];
        muted = m;
        save();
    }
    function save() {
        store.setText(JSON.stringify({ muted: muted, seen: seen }));
    }
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
            const app = n.appName !== "" ? n.appName : "Unknown";
            if (root.seen.indexOf(app) < 0) {
                root.seen = root.seen.concat([app]);
                root.save();
            }
            // Muted app: never tracked, so it neither collects in the shade nor shows a banner.
            if (root.muted[app])
                return;
            n.tracked = true;
            if (!root.dnd) {
                root.banner = { app: n.appName, summary: n.summary, body: n.body };
                bannerTimer.restart();
            }
        }
    }

    FileView {
        id: store
        path: root.file
        atomicWrites: true
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.muted = d.muted || {};
                root.seen = d.seen || [];
            } catch (e) {}
        }
    }

    Timer {
        id: bannerTimer
        interval: 5000
        onTriggered: root.banner = null
    }
}

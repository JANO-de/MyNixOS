import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Settings > Android apps: Droidloom runtime, shared folder, installed Android apps.
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    property string rt: "..." // systemctl is-active droidloom.service
    readonly property bool up: rt === "active"
    readonly property var apps: {
        const l = [];
        for (const e of DesktopEntries.applications.values)
            if (Apps.isAndroid(e))
                l.push(e);
        l.sort((a, b) => String(a.name).localeCompare(String(b.name)));
        return l;
    }

    function refresh() {
        st.running = false;
        st.running = true;
    }
    function ctl(verb) {
        Quickshell.execDetached(["systemctl", "--user", verb, "droidloom.service"]);
        recheck.restart();
    }

    Component.onCompleted: refresh()
    Timer {
        id: recheck
        interval: 3000
        onTriggered: page.refresh()
    }
    Process {
        id: st
        command: ["systemctl", "--user", "is-active", "droidloom.service"]
        stdout: StdioCollector { onStreamFinished: page.rt = text.trim() }
    }

    SetGroup {
        title: "Android runtime"
        SetRow {
            glyph: "◈"
            title: page.up ? "Running" : (page.rt === "activating" ? "Starting..." : "Stopped")
            subtitle: "Starts with the first Android app and keeps running"
            tappable: false

            Row {
                spacing: 8
                SetButton {
                    visible: !page.up
                    text: "Start"
                    accent: true
                    onClicked: page.ctl("start")
                }
                SetButton {
                    visible: page.up
                    text: "Restart"
                    onClicked: page.ctl("restart")
                }
                SetButton {
                    visible: page.up
                    text: "Stop"
                    onClicked: page.ctl("stop")
                }
            }
        }
    }

    SetGroup {
        title: "Files"
        SetRow {
            glyph: "▤"
            title: "Shared folder"
            subtitle: "~/Shared is visible to Android as /sdcard/Shared"
            chevron: true
            onClicked: Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/Shared"])
        }
    }

    SetGroup {
        title: page.apps.length + " Android apps"

        Repeater {
            model: page.apps

            SetRow {
                required property var modelData

                icon: String(modelData.icon || "")
                title: modelData.name
                subtitle: String(modelData.startupClass || "")
                chevron: true
                onClicked: Apps.run(modelData)
            }
        }
        SetRow {
            visible: page.apps.length === 0
            title: "No Android apps"
            subtitle: "Install F-Droid and Aurora Store with scripts/halos1-android-apps.sh"
            tappable: false
        }
    }
}

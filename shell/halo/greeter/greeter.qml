// Halo greeter: greetd login screen (touch first: on-screen keyboard; a physical keyboard works too).
// Run by greetd inside cage (modules/desktop/greeter.nix). Preview inside a session (no login happens):
//   quickshell -p ~/halo/greeter/greeter.qml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

ShellRoot {
    FloatingWindow {
        id: win
        visible: true
        title: "Halo greeter"
        color: "#0e1617"

        readonly property string user: Quickshell.env("HALO_GREETER_USER") || "jano"
        readonly property string uwsm: Quickshell.env("HALO_UWSM") || ""
        readonly property string sh: Quickshell.env("HALO_SH") || "sh"
        readonly property string systemctl: Quickshell.env("HALO_SYSTEMCTL") || "systemctl"
        readonly property string sessionsDir: Quickshell.env("HALO_SESSIONS") || "/run/current-system/sw/share/wayland-sessions"
        property var sessions: ["hyprland-uwsm.desktop"]
        property int sessionIdx: 0
        readonly property string session: sessions[sessionIdx] || "hyprland-uwsm.desktop"
        property int batt: -1
        property string battState: ""
        property bool wifiUp: false
        property string armed: ""
        property bool imageWall: false
        property string wc1: "#16292b"
        property string wc2: "#0a1112"
        readonly property bool demo: !Quickshell.env("GREETD_SOCK")
        property string msg: ""
        property bool busy: false
        property string pending: ""
        property bool leaving: false

        function submit() {
            if (busy || field.text === "")
                return;
            if (demo) {
                msg = "Preview only (no greetd here)";
                field.text = "";
                return;
            }
            pending = field.text;
            field.text = "";
            msg = "";
            busy = true;
            Greetd.createSession(user);
        }

        Connections {
            target: Greetd
            function onAuthMessage(message, error, responseRequired, echoResponse) {
                if (responseRequired)
                    Greetd.respond(win.pending);
            }
            function onAuthFailure(message) {
                win.pending = "";
                win.busy = false;
                win.msg = "Wrong password";
                Greetd.cancelSession();
            }
            function onReadyToLaunch() {
                win.pending = "";
                win.leaving = true;
                launchT.start();
            }
        }

        Timer {
            id: launchT
            interval: 2000
            // Direct launch (as in update 46, worked). The sh -c wrapper of 47/49 made the session die in 1 s with an empty log.
            onTriggered: Greetd.launch([win.uwsm, "start", win.session], [], true)
        }

        SystemClock { id: clock; precision: SystemClock.Minutes }

        function prettySession(n) {
            const b = n.replace(".desktop", "").replace("-uwsm", "").replace(/-/g, " ");
            return b.charAt(0).toUpperCase() + b.slice(1);
        }

        // Battery, Wi-Fi and sessions via shell builtins only (the greeter has no PATH).
        Process {
            id: statusProc
            command: [win.sh, "-c", "for f in /sys/class/power_supply/BAT*; do [ -r \"$f/capacity\" ] || continue; read c < \"$f/capacity\"; read s < \"$f/status\"; echo \"B $c $s\"; break; done; w=0; for d in /sys/class/net/*/wireless; do [ -d \"$d\" ] || continue; n=${d%/wireless}; read o < \"$n/operstate\"; [ \"$o\" = up ] && w=1; done; echo \"W $w\"; for f in \"$1\"/*.desktop; do [ -e \"$f\" ] && echo \"S ${f##*/}\"; done", "halo", win.sessionsDir]
            stdout: StdioCollector {
                onStreamFinished: {
                    const ss = [];
                    for (const l of text.split("\n")) {
                        const f = l.trim().split(" ");
                        if (f[0] === "B") {
                            win.batt = parseInt(f[1]);
                            win.battState = f[2] || "";
                        } else if (f[0] === "W") {
                            win.wifiUp = f[1] === "1";
                        } else if (f[0] === "S" && f[1]) {
                            ss.push(f[1]);
                        }
                    }
                    if (ss.length > 0 && ss.join("|") !== win.sessions.join("|")) {
                        win.sessions = ss;
                        const i = ss.indexOf("hyprland-uwsm.desktop");
                        win.sessionIdx = i >= 0 ? i : 0;
                    }
                }
            }
        }
        Timer {
            interval: 10000
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: if (!statusProc.running) statusProc.running = true
        }

        // Wallpaper mirror written by the shell (services/Wallpaper.qml).
        FileView {
            id: themeFile
            path: "/var/lib/halo-greeter/theme.json"
            onLoaded: {
                try {
                    const t = JSON.parse(text());
                    win.imageWall = t.image === true;
                    if (t.c1) win.wc1 = t.c1;
                    if (t.c2) win.wc2 = t.c2;
                } catch (e) {}
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: win.wc1 }
                GradientStop { position: 1; color: win.wc2 }
            }
        }
        Image {
            anchors.fill: parent
            visible: win.imageWall && status === Image.Ready
            source: win.imageWall ? "file:///var/lib/halo-greeter/wallpaper" : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 1920
        }
        Rectangle {
            anchors.fill: parent
            color: win.imageWall ? Qt.rgba(0, 0, 0, 0.35) : "transparent"
        }

        // Top bar: power buttons (tap twice) left, Wi-Fi + battery right.
        Row {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10
            Repeater {
                model: [
                    { id: "suspend", icon: "sleep", label: "Sleep" },
                    { id: "reboot", icon: "restart", label: "Restart" },
                    { id: "poweroff", icon: "power", label: "Power off" }
                ]
                Rectangle {
                    required property var modelData
                    readonly property bool arm: win.armed === modelData.id
                    width: arm ? armLabel.implicitWidth + 44 : 40
                    height: 40
                    radius: 20
                    color: arm ? "#ff9a9a" : Qt.rgba(1, 1, 1, 0.14)
                    Behavior on width { NumberAnimation { duration: 140 } }
                    GIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 9
                        size: 22
                        name: modelData.icon
                        color: arm ? "#2a0d0d" : "white"
                    }
                    Text {
                        id: armLabel
                        anchors.verticalCenter: parent.verticalCenter
                        x: 38
                        visible: arm
                        text: "Tap again"
                        color: "#2a0d0d"
                        font.pixelSize: 14
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (win.armed === modelData.id) {
                                win.armed = "";
                                if (!win.demo)
                                    Quickshell.execDetached([win.systemctl, modelData.id]);
                                else
                                    win.msg = "Preview only: " + modelData.label;
                            } else {
                                win.armed = modelData.id;
                                armT.restart();
                            }
                        }
                    }
                }
            }
        }
        Timer { id: armT; interval: 3000; onTriggered: win.armed = "" }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            spacing: 14
            GIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: 24
                name: "wifi"
                color: "white"
                opacity: win.wifiUp ? 0.9 : 0.3
            }
            Row {
                visible: win.batt >= 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                GIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 26
                    name: "battery"
                    color: win.battState === "Charging" ? "#9ed69a" : (win.batt <= 15 ? "#ff9a9a" : "white")
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.batt + "%"
                    color: "white"
                    font.pixelSize: 16
                }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.08
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, "hh:mm")
                color: "white"
                font.pixelSize: 84
                font.weight: Font.Light
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(clock.date, "dddd, d MMMM")
                color: Qt.rgba(1, 1, 1, 0.7)
                font.pixelSize: 20
            }
        }

        Column {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.34
            spacing: 16
            width: Math.min(parent.width - 48, 420)

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96
                height: 96
                radius: 48
                color: "#2a4547"
                Text {
                    anchors.centerIn: parent
                    text: win.user.charAt(0).toUpperCase()
                    color: "white"
                    font.pixelSize: 44
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: win.user
                color: "white"
                font.pixelSize: 24
                font.weight: Font.DemiBold
            }
            Rectangle {
                width: parent.width
                height: 56
                radius: 28
                color: Qt.rgba(1, 1, 1, 0.14)
                border.width: field.activeFocus ? 2 : 0
                border.color: "#7fd1c7"
                TextInput {
                    id: field
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: "white"
                    font.pixelSize: 22
                    enabled: !win.busy
                    focus: true
                    Component.onCompleted: forceActiveFocus()
                    onAccepted: win.submit()
                    Text {
                        visible: field.text === ""
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: win.busy ? "Logging in\u2026" : "Password"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 22
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: win.msg
                color: "#ff9a9a"
                font.pixelSize: 16
                height: 20
            }
            Rectangle {
                visible: win.sessions.length > 1
                anchors.horizontalCenter: parent.horizontalCenter
                width: sessLabel.implicitWidth + 32
                height: 34
                radius: 17
                color: Qt.rgba(1, 1, 1, 0.14)
                Text {
                    id: sessLabel
                    anchors.centerIn: parent
                    text: win.prettySession(win.session) + "  \u25BE"
                    color: "white"
                    font.pixelSize: 15
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: win.sessionIdx = (win.sessionIdx + 1) % win.sessions.length
                }
            }
        }

        GKeyboard {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            height: implicitHeight
            target: field
            onEnter: win.submit()
        }

        // Fade to the same breathing ring as the boot splash while the session starts.
        Rectangle {
            anchors.fill: parent
            color: "#0a1112"
            opacity: win.leaving ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 450 } }
            Rectangle {
                id: lring
                anchors.centerIn: parent
                width: 190
                height: 190
                radius: 95
                color: "transparent"
                border.width: 11
                border.color: "#bef0e8"
                property real ph: 0
                NumberAnimation on ph { running: win.leaving; from: 0; to: 6.2832; duration: 1800; loops: Animation.Infinite }
                opacity: 0.7 + 0.3 * Math.sin(ph)
                Row {
                    anchors.centerIn: parent
                    spacing: 3
                    Repeater {
                        model: ["H", "A", "L", "O", "S"]
                        Text {
                            required property string modelData
                            required property int index
                            text: modelData
                            color: "#bef0e8"
                            font.pixelSize: 30
                            font.weight: Font.Bold
                            opacity: 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(lring.ph * 2 - index * 0.9))
                        }
                    }
                }
            }
        }
    }
}

// Halo greeter: greetd login screen (touch first: on-screen keyboard; a physical keyboard works too).
// Run by greetd inside cage (modules/desktop/greeter.nix). Preview inside a session (no login happens):
//   quickshell -p ~/halo/greeter/greeter.qml
import QtQuick
import Quickshell
import Quickshell.Services.Greetd

ShellRoot {
    FloatingWindow {
        id: win
        visible: true
        title: "Halo greeter"
        color: "#0e1617"

        readonly property string user: Quickshell.env("HALO_GREETER_USER") || "jano"
        readonly property string uwsm: Quickshell.env("HALO_UWSM") || ""
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
            interval: 650
            onTriggered: Greetd.launch([win.uwsm, "start", "hyprland-uwsm.desktop"], [], true)
        }

        SystemClock { id: clock; precision: SystemClock.Minutes }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "#16292b" }
                GradientStop { position: 1; color: "#0a1112" }
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
                anchors.centerIn: parent
                width: 150
                height: 150
                radius: 75
                color: "transparent"
                border.width: 11
                border.color: "#bef0e8"
                SequentialAnimation on opacity {
                    running: win.leaving
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.4; to: 1; duration: 800; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}

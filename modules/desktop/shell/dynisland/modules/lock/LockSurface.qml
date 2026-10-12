// One lock screen (per monitor): blurred wallpaper, big clock, user, password pill.
// `lock` is Lock.qml (holds the PAM state shared by all monitors).
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

WlSessionLockSurface {
    id: s
    property var lock
    color: "black"                       // shown until the first frame

    readonly property string user: Quickshell.env("USER") || "user"

    Item {
        id: view
        anchors.fill: parent
        opacity: 0
        NumberAnimation on opacity { to: 1; duration: 350; running: true }   // fade in

        // wallpaper -> blurred + darkened
        Image {
            id: bg; visible: false; anchors.fill: parent; asynchronous: true
            source: Config.appearance.wallpaper ? "file://" + Config.appearance.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: s.width; sourceSize.height: s.height
        }
        MultiEffect { anchors.fill: parent; source: bg; blurEnabled: true; blurMax: 64; blur: 1.0; brightness: -0.25 }
        Rectangle { anchors.fill: parent; color: Theme.surface; opacity: 0.35 }

        // click anywhere -> keyboard focus (multi-monitor: only one surface has it)
        MouseArea { anchors.fill: parent; onClicked: pw.forceActiveFocus() }

        // toggleable info cards along the bottom (Config.lock.*)
        LockWidgets { anchors.fill: parent }

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Clock.time
                   color: "white"; font.pixelSize: 120; font.weight: Font.Light }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Clock.dateLong
                   color: "#ccffffff"; font.pixelSize: 22 }
            Item { width: 1; height: 48 }

            // avatar: first letter of the user name in an accent circle
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 84; height: 84; radius: 42; color: Theme.primary
                Text { anchors.centerIn: parent; text: s.user.charAt(0).toUpperCase()
                       color: Theme.primaryFg; font.pixelSize: 38; font.weight: Font.DemiBold }
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: s.user
                   color: "white"; font.pixelSize: 18; topPadding: 8; bottomPadding: 10 }

            // password pill
            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300; height: 46; radius: 23
                color: "#2effffff"
                border.width: 1
                border.color: s.lock.error !== "" ? "#ff6b6b" : (pw.activeFocus ? Theme.primary : "#33ffffff")
                Behavior on border.color { ColorAnimation { duration: 150 } }
                transform: Translate { id: shift }

                // shake on a wrong password
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: shift; property: "x"; to: -14; duration: 55 }
                    NumberAnimation { target: shift; property: "x"; to: 14;  duration: 90 }
                    NumberAnimation { target: shift; property: "x"; to: -9;  duration: 80 }
                    NumberAnimation { target: shift; property: "x"; to: 0;   duration: 60 }
                }
                Connections { target: s.lock; function onFailed() { pw.text = ""; shake.restart() } }

                Icon { anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                       name: "lock"; size: 18; color: "#aaffffff" }
                TextInput {
                    id: pw
                    anchors { fill: parent; leftMargin: 44; rightMargin: 16 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password; passwordCharacter: "\u2022"
                    color: "white"; font.pixelSize: 16; clip: true
                    enabled: !s.lock.busy
                    focus: true
                    onAccepted: s.lock.submit(text)
                    Keys.onEscapePressed: text = ""
                    onTextChanged: if (text !== "" && s.lock.error !== "") s.lock.error = ""
                    Text { visible: pw.text === ""; anchors.verticalCenter: parent.verticalCenter
                           text: s.lock.busy ? "Checking..." : "Password"; color: "#88ffffff"; font.pixelSize: 15 }
                }
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; topPadding: 10
                   text: s.lock.error; color: "#ff8a8a"; font.pixelSize: 13
                   opacity: s.lock.error !== "" ? 1 : 0 }
        }
    }

    Component.onCompleted: pw.forceActiveFocus()
}

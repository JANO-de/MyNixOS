import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import qs.services

// One lock surface: wallpaper, big clock, notification titles, media, swipe up for the passcode.
Item {
    id: root

    // 0 = lock screen, 1 = passcode / password
    property real reveal: 0
    property bool dragging: false
    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    readonly property var battery: UPower.displayDevice

    Behavior on reveal {
        enabled: !root.dragging
        NumberAnimation { duration: 380; easing.type: Easing.OutQuint }
    }

    Connections {
        target: Lock
        function onLockedChanged() {
            if (Lock.locked)
                root.reveal = 0;
        }
        function onStageChanged() {
            root.reveal = Lock.stage === "hero" ? 0 : 1;
            if (Lock.stage === "password")
                field.forceActiveFocus();
        }
    }

    function openUnlock() {
        Lock.error = "";
        Lock.stage = Lock.hasPin ? "pin" : "password";
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    WallpaperView {
        anchors.fill: parent
        spec: Wallpaper.current
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.25 + 0.3 * root.reveal)
    }

    // ---- Lock screen ---------------------------------------------------------------------------
    Item {
        id: hero
        anchors.fill: parent
        opacity: 1 - Math.min(1, root.reveal * 1.4)
        y: -root.reveal * 70
        visible: opacity > 0.01 || root.dragging

        Column {
            id: clockCol
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.1
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                color: Theme.text
                opacity: 0.9
                font.pixelSize: 24
                font.weight: Font.Medium
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.text
                font.pixelSize: Math.min(180, root.height * 0.17)
                font.weight: Font.Light
            }
        }

        Text {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 28
            visible: root.battery !== null && root.battery.isPresent
            text: root.battery ? Math.round(root.battery.percentage * 100) + "%" : ""
            color: Theme.text
            font.pixelSize: 16
        }

        // Notifications (titles only while locked)
        Column {
            id: notifs
            anchors.top: clockCol.bottom
            anchors.topMargin: 48
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 48, 560)
            spacing: 10

            Repeater {
                model: Notifs.list

                Rectangle {
                    required property int index
                    required property var modelData
                    visible: index < 4
                    width: notifs.width
                    height: visible ? nCol.implicitHeight + 24 : 0
                    radius: 22
                    color: Qt.rgba(0.13, 0.13, 0.16, 0.6)
                    border.color: Theme.glassStroke
                    border.width: 1

                    Column {
                        id: nCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 16
                        spacing: 2
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: parent.parent.modelData.appName
                            color: Theme.dim
                            font.pixelSize: 12
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: parent.parent.modelData.summary
                            color: Theme.text
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }

        // Media
        Rectangle {
            visible: root.player !== null
            anchors.bottom: unlockZone.top
            anchors.bottomMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 48, 560)
            height: 150
            radius: 28
            color: Qt.rgba(0.13, 0.13, 0.16, 0.6)
            border.color: Theme.glassStroke
            border.width: 1

            WidgetMedia {
                anchors.fill: parent
                anchors.margins: 16
            }
        }

        // Swipe-up zone
        Item {
            id: unlockZone
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 170

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 34
                spacing: 12

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 150
                    height: 6
                    radius: 3
                    color: Theme.text
                    opacity: 0.8
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Swipe up to unlock"
                    color: Theme.text
                    opacity: 0.75
                    font.pixelSize: 15
                }
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true

                property real startY: 0
                property real lastY: 0
                property real lastT: 0
                property real vel: 0 // px/ms, + is up

                function gy(m) {
                    return mapToItem(null, m.x, m.y).y;
                }

                onPressed: mouse => {
                    startY = gy(mouse);
                    lastY = startY;
                    lastT = Date.now();
                    vel = 0;
                    root.dragging = true;
                }
                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    const y = gy(mouse);
                    root.reveal = Math.max(0, Math.min(1, (startY - y) / (root.height * 0.35)));
                    const now = Date.now();
                    const dt = now - lastT;
                    if (dt > 0)
                        vel = 0.7 * vel + 0.3 * ((lastY - y) / dt);
                    lastY = y;
                    lastT = now;
                }
                onReleased: {
                    root.dragging = false;
                    if (root.reveal > 0.25 || vel > 0.6)
                        root.openUnlock();
                    else
                        root.reveal = 0;
                }
                onCanceled: {
                    root.dragging = false;
                    if (root.reveal > 0.25)
                        root.openUnlock();
                    else
                        root.reveal = 0;
                }
                onClicked: root.openUnlock()
            }
        }
    }

    // ---- Passcode / password ---------------------------------------------------------------------
    Item {
        id: auth
        anchors.fill: parent
        opacity: root.reveal
        y: (1 - root.reveal) * 140
        visible: opacity > 0.01

        PinPad {
            visible: Lock.stage === "pin"
            anchors.centerIn: parent
            length: Lock.pinLen
            onSubmit: pin => Lock.submitPin(pin)
            onCancel: Lock.stage = "hero"
            onUsePassword: {
                Lock.error = "";
                Lock.stage = "password";
            }
        }

        Column {
            visible: Lock.stage === "password"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -parent.height * 0.12
            width: Math.min(parent.width - 48, 760)
            spacing: 22

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Lock.cooling ? "Try again in " + Lock.cooldownSecs + " s" : (Lock.error !== "" ? Lock.error : (Lock.hasPin ? "Enter password" : "Enter password (no PIN set: run halo-set-pin)"))
                color: Theme.text
                font.pixelSize: 20
                font.weight: Font.Medium
            }

            Rectangle {
                width: Math.min(parent.width, 520)
                height: 56
                radius: 28
                anchors.horizontalCenter: parent.horizontalCenter
                color: Qt.rgba(1, 1, 1, 0.16)

                TextInput {
                    id: field
                    anchors.fill: parent
                    anchors.leftMargin: 26
                    anchors.rightMargin: 26
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    font.pixelSize: 20
                    clip: true
                    onAccepted: {
                        Lock.submitPassword(text);
                        text = "";
                    }
                }
            }

            LockKeyboard {
                width: parent.width
                target: field
                onEnter: {
                    Lock.submitPassword(field.text);
                    field.text = "";
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 60

                Text {
                    text: "Cancel"
                    color: Theme.text
                    font.pixelSize: 17
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -14
                        onClicked: Lock.stage = "hero"
                    }
                }
                Text {
                    visible: Lock.hasPin
                    text: "Use passcode"
                    color: Theme.text
                    font.pixelSize: 17
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -14
                        onClicked: {
                            Lock.error = "";
                            Lock.stage = "pin";
                        }
                    }
                }
            }
        }
    }
}

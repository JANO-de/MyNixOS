import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

// Android-style pull-down: quick tiles + brightness/volume sliders.
// Opened by UI.shadeOpen (IPC `shade toggle`, top-edge swipe, SUPER+N, island long tap later).
PanelWindow {
    id: root

    readonly property bool shown: UI.shadeOpen

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    visible: shown || panel.opacity > 0.01
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-shade"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    onShownChanged: {
        if (shown)
            System.refresh();
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.shown
        onTriggered: System.refresh()
    }

    Process {
        id: modeToggler
        command: ["hyprctl", "eval", "set_mode(\"" + (Mode.tablet ? "desktop" : "tablet") + "\")"]
    }

    Process {
        id: kbd
        command: ["kbd-toggle"]
    }

    // Dim backdrop: tap outside the panel closes the shade.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        MouseArea {
            anchors.fill: parent
            onClicked: UI.closeShade()
        }
    }

    Rectangle {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 24, 560)
        height: content.implicitHeight + 40
        radius: 32
        color: Qt.rgba(0.13, 0.13, 0.16, 0.72)
        border.color: Theme.glassStroke
        border.width: 1
        opacity: root.shown ? 1 : 0
        y: root.shown ? 12 : -height - 20
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        // Swallow taps on the panel itself.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 14

            Text {
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                color: Theme.dim
                font.pixelSize: 14
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: 12

                QsTile {
                    width: (parent.width - 12) / 2
                    title: "Wi-Fi"
                    subtitle: System.wifi ? (System.wifiName !== "" ? System.wifiName : "On") : "Off"
                    active: System.wifi
                    onClicked: System.toggleWifi()
                }
                QsTile {
                    width: (parent.width - 12) / 2
                    title: "Bluetooth"
                    subtitle: System.bluetooth ? "On" : "Off"
                    active: System.bluetooth
                    onClicked: System.toggleBluetooth()
                }
                QsTile {
                    width: (parent.width - 12) / 2
                    title: Mode.tablet ? "Tablet mode" : "Desktop mode"
                    subtitle: "Tap to switch"
                    active: Mode.tablet
                    onClicked: {
                        modeToggler.running = true;
                        UI.closeShade();
                    }
                }
                QsTile {
                    width: (parent.width - 12) / 2
                    title: "Keyboard"
                    subtitle: "On-screen"
                    onClicked: {
                        kbd.running = true;
                        UI.closeShade();
                    }
                }
            }

            QsSlider {
                width: parent.width
                label: "Brightness"
                value: System.brightness
                onMoved: v => System.setBrightness(v)
            }

            QsSlider {
                width: parent.width
                label: System.muted ? "Volume (muted)" : "Volume"
                value: System.muted ? 0 : System.volume
                onMoved: v => System.setVolume(v)
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}

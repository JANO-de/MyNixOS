import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

// Dynamic Island placeholder: clock + mode dot. Tap toggles tablet/desktop.
PanelWindow {
    id: root

    anchors.top: true
    margins.top: 8
    implicitWidth: 150
    implicitHeight: 38
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-island"
    WlrLayershell.layer: WlrLayer.Top

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Process {
        id: toggler
        command: ["hyprctl", "eval", "set_mode(\"" + (Mode.tablet ? "desktop" : "tablet") + "\")"]
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "#000000"

        Row {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: Mode.tablet ? Theme.accent : Theme.dim
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: toggler.running = true
        }
    }
}

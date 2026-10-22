// Server mode settings (see services/Server.qml). Toggle the mode itself from here or the Power panel.
import QtQuick
import qs.config
import qs.services
import qs.components

Page {
    title: "Server"
    Rectangle {   // status strip
        width: parent.width; height: 44; radius: 14
        color: Server.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18) : Qt.rgba(1,1,1,0.06)
        border.width: 1; border.color: Server.active ? Theme.primary : Glass.outline
        Row { anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter } spacing: 8
            Rectangle { width: 9; height: 9; radius: 4.5; anchors.verticalCenter: parent.verticalCenter
                        color: Server.active ? Theme.primary : "#777" }
            Text { text: Server.active ? "Server mode is on" : "Server mode is off"; color: "white"; font.pixelSize: 13; font.weight: Font.Medium
                   anchors.verticalCenter: parent.verticalCenter }
        }
    }
    Item { width: 1; height: 8 }
    SettingRow { label: "Server mode"; hint: Server.status + (Server.active ? "  ·  llama.cpp " + (Server.llamaUp ? "up" : "down") : "")
        PillButton { label: Server.active ? "Turn off" : "Turn on"; icon: "dns"; filled: !Server.active; onClicked: Server.toggle() } }
    SettingRow { label: "Lock on enter"; hint: "Lock the session first, so touching the PC shows the lock screen"
        Toggle { checked: Config.server.lockOnEnter; onToggled: Config.server.lockOnEnter = !Config.server.lockOnEnter } }
    SettingRow { label: "Monitors off"; hint: "power off monitors (any input wakes them)"
        Toggle { checked: Config.server.screensOff; onToggled: Config.server.screensOff = !Config.server.screensOff } }
    SettingRow { label: "LEDs off"; hint: "Runs the commands below (OpenRGB). Fans are not touched"
        Toggle { checked: Config.server.ledsOff; onToggled: Config.server.ledsOff = !Config.server.ledsOff } }
    SettingRow { label: "LEDs off command"; Field { text: Config.server.ledsOffCmd; onAccepted: t => Config.server.ledsOffCmd = t } }
    SettingRow { label: "LEDs on command"; hint: "Run when leaving Server mode"; Field { text: Config.server.ledsOnCmd; onAccepted: t => Config.server.ledsOnCmd = t } }
    SettingRow { label: "Tailscale"; hint: "tailscale up on enter, down on leave. First time: run `tailscale up` once with the screen on"
        Toggle { checked: Config.server.tailscale; onToggled: Config.server.tailscale = !Config.server.tailscale } }
    SettingRow { label: "Tailscale SSH"; hint: "ssh jano@<tailscale name> from any device on your tailnet, no sshd/keys"
        Toggle { checked: Config.server.ssh; onToggled: Config.server.ssh = !Config.server.ssh } }
    SettingRow { label: "Publish llama.cpp web UI"; hint: "tailscale serve: https://<name>.<tailnet>.ts.net (enable HTTPS in the Tailscale admin first)"
        Toggle { checked: Config.server.serve; onToggled: Config.server.serve = !Config.server.serve } }
    SettingRow { label: "llama.cpp port"; Field { text: String(Config.server.port); onAccepted: t => Config.server.port = parseInt(t) || 8080 } }
    SettingRow { label: "Start llama.cpp on enter"; hint: "systemctl start <unit>. It keeps running after Server mode ends"
        Toggle { checked: Config.server.startLlama; onToggled: Config.server.startLlama = !Config.server.startLlama } }
    SettingRow { label: "llama.cpp unit"; hint: "systemd unit name without .service"; Field { text: Config.server.llamaUnit; onAccepted: t => Config.server.llamaUnit = t } }
}

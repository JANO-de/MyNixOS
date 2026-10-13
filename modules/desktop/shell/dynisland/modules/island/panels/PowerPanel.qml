// Power menu. Reboot and shutdown ask for a second tap ("Sure?") so they can't be hit by accident.
// Commands come from Settings > System. "Server" toggles Server mode (services/Server.qml).
import QtQuick
import qs.config
import qs.services
import qs.components

PanelFrame {
    id: p
    title: "Power"; icon: "power_settings_new"
    property int armed: -1
    readonly property var items: [
        { icon: "lock",               label: "Lock",     cmd: "@lock",     confirm: false },
        { icon: "logout",             label: "Log out",  cmd: Config.system.logoutCmd,   confirm: false },
        { icon: "bedtime",            label: "Suspend",  cmd: Config.system.suspendCmd,  confirm: false },
        { icon: "dns",                label: "Server",   cmd: "@server",   confirm: false },
        { icon: "restart_alt",        label: "Reboot",   cmd: Config.system.rebootCmd,   confirm: true },
        { icon: "power_settings_new", label: "Shut down",cmd: Config.system.shutdownCmd, confirm: true }
    ]
    Timer { id: disarm; interval: 3000; onTriggered: p.armed = -1 }

    Row {
        id: row
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: parent.height - (Server.active ? 30 : 0); spacing: 8
        Repeater {
            model: p.items
            Rectangle {
                required property var modelData
                required property int index
                readonly property bool sure: p.armed === index
                readonly property bool isServer: modelData.cmd === "@server"
                width: (row.width - 8 * (p.items.length - 1)) / p.items.length; height: row.height; radius: 18
                color: sure ? "#c0392b" : (isServer && Server.active ? Qt.alpha(Theme.primary, 0.55) : (pma.containsMouse ? "#2affffff" : "#14ffffff"))
                Behavior on color { ColorAnimation { duration: 120 } }
                Column {
                    anchors.centerIn: parent; spacing: 8
                    Icon { anchors.horizontalCenter: parent.horizontalCenter; name: parent.parent.sure ? "warning" : modelData.icon; size: 26; color: "white" }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: 11; color: "white"
                           text: parent.parent.sure ? "Sure?" : (parent.parent.isServer && Server.active ? "Server on" : modelData.label) }
                }
                MouseArea {
                    id: pma; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (modelData.confirm && p.armed !== index) { p.armed = index; disarm.restart(); return }
                        if (!isServer) UiState.closePanel();   // keep the panel open to watch Server mode start
                        Sys.run(modelData.cmd);
                    }
                }
            }
        }
    }
    // Server mode status line: Tailscale name/IP + llama.cpp state
    Text {
        visible: Server.active
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        elide: Text.ElideRight; font.pixelSize: 12; color: "#ccffffff"
        text: Server.status + "  ·  llama.cpp " + (Server.llamaUp ? "up" : "down")
    }
}

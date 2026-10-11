// Power commands (run through `sh -c`), config folder, shell reload.
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Page {
    title: "System"
    SettingRow { label: "Lock command" ; Field { text: Config.system.lockCmd; onAccepted: t => Config.system.lockCmd = t } }
    SettingRow { label: "Logout command"; Field { text: Config.system.logoutCmd; onAccepted: t => Config.system.logoutCmd = t } }
    SettingRow { label: "Reboot command"; Field { text: Config.system.rebootCmd; onAccepted: t => Config.system.rebootCmd = t } }
    SettingRow { label: "Shutdown command"; Field { text: Config.system.shutdownCmd; onAccepted: t => Config.system.shutdownCmd = t } }
    SettingRow { label: "Config file"; hint: Config.dir + "/config.json"
        PillButton { label: "Open folder"; icon: "folder_open"; onClicked: Quickshell.execDetached(["xdg-open", Config.dir]) } }
    SettingRow { label: "Reload shell"; hint: "Restarts all windows (unsaved changes are kept in memory only)"
        PillButton { label: "Reload"; icon: "restart_alt"; onClicked: Quickshell.reload(true) } }
}

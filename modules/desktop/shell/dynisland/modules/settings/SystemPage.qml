// Power commands (run through `sh -c`), config folder, shell reload.
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Page {
    title: "System"
    SettingRow { label: "Terminal"; hint: "Runs launcher \"> commands\" (needs -e support)"; Field { text: Config.system.terminal; onAccepted: t => Config.system.terminal = t } }
    SettingRow { label: "Built-in lock screen"; hint: "Off = run the lock command below instead"
        Toggle { checked: Config.system.builtinLock; onToggled: Config.system.builtinLock = !Config.system.builtinLock } }
    SettingRow { label: "Lock PAM service"; hint: "File in /etc/pam.d (login works on NixOS)"; Field { text: Config.system.pamService; onAccepted: t => Config.system.pamService = t } }
    SettingRow { label: "Emergency unlock via IPC"; hint: "qs ipc call lock unlock. Turn off once the lock works"
        Toggle { checked: Config.system.lockIpcUnlock; onToggled: Config.system.lockIpcUnlock = !Config.system.lockIpcUnlock } }
    SettingRow { label: "Lock command" ; Field { text: Config.system.lockCmd; onAccepted: t => Config.system.lockCmd = t } }
    SettingRow { label: "Screenshot folder"; Field { text: Config.system.screenshotDir; onAccepted: t => Config.system.screenshotDir = t } }
    SettingRow { label: "Recording folder"; Field { text: Config.system.recordDir; onAccepted: t => Config.system.recordDir = t } }
    SettingRow { label: "Night light temperature"; hint: "Lower = warmer. Applied while the night light button is on"
        SSlider { from: 2500; to: 6500; stepSize: 100; suffix: "K"; value: Config.system.nightLightTemp; onMoved: v => Config.system.nightLightTemp = v } }
    SettingRow { label: "Focus mode dim"; hint: "Wallpaper darkening while Focus mode is on"
        SSlider { from: 0; to: 0.8; stepSize: 0.05; value: Config.system.focusDim; onMoved: v => Config.system.focusDim = v } }
    SettingRow { label: "Screenshot command"; hint: "%f = file path to save to (region picker by default)"
        Field { implicitWidth: 320; text: Config.system.screenshotCmd; onAccepted: t => Config.system.screenshotCmd = t } }
    SettingRow { label: "Logout command"; Field { text: Config.system.logoutCmd; onAccepted: t => Config.system.logoutCmd = t } }
    SettingRow { label: "Suspend command"; Field { text: Config.system.suspendCmd; onAccepted: t => Config.system.suspendCmd = t } }
    SettingRow { label: "Reboot command"; Field { text: Config.system.rebootCmd; onAccepted: t => Config.system.rebootCmd = t } }
    SettingRow { label: "Shutdown command"; Field { text: Config.system.shutdownCmd; onAccepted: t => Config.system.shutdownCmd = t } }
    SettingRow { label: "Drive notifications"; hint: "Connected, mounted, unmounted, removed"
        Toggle { checked: Config.system.usbNotify; onToggled: Config.system.usbNotify = !Config.system.usbNotify } }
    SettingRow { label: "Update indicator"; hint: "Shows when flake.lock is older than the days below"
        Toggle { checked: Config.system.updateCheck; onToggled: Config.system.updateCheck = !Config.system.updateCheck } }
    SettingRow { label: "Update after"; SSlider { from: 1; to: 30; stepSize: 1; suffix: " days"; value: Config.system.updateDays; onMoved: v => Config.system.updateDays = v } }
    SettingRow { label: "Flake folder"; Field { implicitWidth: 260; text: Config.system.flakeDir; onAccepted: t => Config.system.flakeDir = t } }
    SettingRow { label: "Update command"; hint: "Run in the terminal above when the indicator is clicked"
        Field { implicitWidth: 320; text: Config.system.updateCmd; onAccepted: t => Config.system.updateCmd = t } }
    SettingRow { label: "Quick note file"; Field { implicitWidth: 260; text: Config.system.noteFile; onAccepted: t => Config.system.noteFile = t } }
    SettingRow { label: "Config file"; hint: Config.dir + "/config.json"
        PillButton { label: "Open folder"; icon: "folder_open"; onClicked: Quickshell.execDetached(["xdg-open", Config.dir]) } }
    SettingRow { label: "Reload shell"; hint: "Restarts all windows (unsaved changes are kept in memory only)"
        PillButton { label: "Reload"; icon: "restart_alt"; onClicked: Quickshell.reload(true) } }
}

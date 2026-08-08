pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * A service that provides access to niri keybinds.
 * Uses the `get_keybinds.py` script to parse config.kdl's `binds` block and
 * convert to JSON (same shape as the Hyprland one, so LauncherSearch can
 * render it without changes).
 */
Singleton {
    id: root
    property string keybindParserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/niri/get_keybinds.py`)
    property string keybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/niri/config.kdl`)
    property var keybinds: {"children": []}

    Process {
        id: getKeybinds
        running: true
        command: [root.keybindParserPath, "--path", root.keybindConfigPath]

        stdout: SplitParser {
            onRead: data => {
                try {
                    root.keybinds = JSON.parse(data)
                } catch (e) {
                    console.error("[CheatsheetKeybinds] Error parsing keybinds:", e)
                }
            }
        }
    }
}

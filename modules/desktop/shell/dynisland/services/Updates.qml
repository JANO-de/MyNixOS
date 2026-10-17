// Update indicator: flake.lock older than Config.system.updateDays => `pending`.
// Updates.run() opens a terminal and runs Config.system.updateCmd.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root
    property bool ready: true
    property real ageDays: 0
    readonly property bool pending: Config.system.updateCheck && ageDays >= Config.system.updateDays

    function run() {
        Quickshell.execDetached([Config.system.terminal, "-e", "bash", "-lc", Config.system.updateCmd]);
    }
    Timer { interval: 600000; repeat: true; running: Config.system.updateCheck; triggeredOnStart: true; onTriggered: p.running = true }
    Process {
        id: p
        command: ["stat", "-c", "%Y", Config.system.flakeDir + "/flake.lock"]
        stdout: StdioCollector { onStreamFinished: { const s = Number(text.trim()); if (s > 0) root.ageDays = (Date.now() / 1000 - s) / 86400 } }
    }
}

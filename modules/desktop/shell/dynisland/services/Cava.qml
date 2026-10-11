// =============================================================================
//  Cava — runs `cava` and exposes the spectrum.
//    Cava.values  array of barCount numbers, each 0..1
//    Cava.level   0..1 bass-weighted loudness (drives glow / pulse)
//  Runs only when the visualizer is enabled and style != "none".
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root
    readonly property int barCount: 24   // keep in sync with cava.conf
    property var values: new Array(barCount).fill(0)
    property real level: 0

    Process {
        running: Config.cava.enabled && Config.cava.style !== "none"
        command: ["cava", "-p", Quickshell.shellPath("cava.conf")]
        stdout: SplitParser {
            onRead: line => {   // one frame per line: "12;40;99;...;"
                const p = line.split(";");
                const out = [];
                for (let i = 0; i < root.barCount; i++) out.push((parseInt(p[i]) || 0) / 100);
                root.values = out;
                root.level = (out[0] + out[1] + out[2] + out[3] + out[4]) / 5;   // bass
            }
        }
        onRunningChanged: if (!running) { root.values = new Array(root.barCount).fill(0); root.level = 0 }
    }
}

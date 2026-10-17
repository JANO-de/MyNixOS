// Second page of the expanded island's right column (chevron at the island's right edge, or
// `dynisland ipc quick toggle`): night light, keep awake, recording, focus, power profile, clipboard.
// TO ADD A TOGGLE: drop another QuickTile in the grid.
import QtQuick
import QtQuick.Layouts
import qs.services

GridLayout {
    columns: 3; rowSpacing: 8; columnSpacing: 8
    QuickTile { icon: "bedtime"; label: "Night"; active: Sys.nightLight; onClicked: Sys.toggleNightLight()
                tip: Sys.nightLight ? "Night light: on" : "Night light: off" }
    QuickTile { icon: Sys.inhibit ? "visibility" : "visibility_off"; label: "Awake"; active: Sys.inhibit; onClicked: Sys.toggleInhibit()
                tip: Sys.inhibit ? "Keep awake: on" : "Keep awake: off" }
    QuickTile { icon: Sys.recording ? "stop_circle" : "radio_button_checked"; label: Sys.recording ? "Stop" : "Record"; active: Sys.recording
                onClicked: Sys.toggleRecording(); tip: Sys.recording ? "Stop screen recording" : "Record screen (pick area)" }
    QuickTile { icon: "block"; label: "Focus"; active: Sys.focusMode; onClicked: Sys.toggleFocus()
                tip: Sys.focusMode ? "Focus mode: on (DND + dim)" : "Focus mode: off" }
    QuickTile { visible: Sys.powerProfile !== ""; active: Sys.powerProfile !== "balanced"; onClicked: Sys.cyclePowerProfile()
                icon: Sys.powerProfile === "performance" ? "speed" : (Sys.powerProfile === "power-saver" ? "battery_saver" : "balance")
                label: Sys.powerProfile === "performance" ? "Perf" : (Sys.powerProfile === "power-saver" ? "Saver" : "Balanced")
                tip: "Power profile: " + Sys.powerProfile }
    QuickTile { icon: "assignment"; label: "Clipboard"; onClicked: UiState.openPanel("clipboard"); tip: "Clipboard history" }
}

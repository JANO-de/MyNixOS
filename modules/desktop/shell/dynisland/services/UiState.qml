// Shared UI state (what is open right now).
pragma Singleton
import Quickshell

Singleton {
    property bool settingsOpen: false
    property bool islandPinned: false   // keep island expanded (IPC: island toggle)
}

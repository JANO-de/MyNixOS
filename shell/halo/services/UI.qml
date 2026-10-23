pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared shell state + IPC entry points.
//   quickshell ipc --newest call home toggle|open|close
Singleton {
    id: root

    property bool homeOpen: false

    function openHome() { homeOpen = true; }
    function closeHome() { homeOpen = false; }
    function toggleHome() { homeOpen = !homeOpen; }

    IpcHandler {
        target: "home"

        function toggle(): void { root.toggleHome(); }
        function open(): void { root.openHome(); }
        function close(): void { root.closeHome(); }
    }
}

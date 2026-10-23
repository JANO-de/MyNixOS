pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared shell state + IPC entry points.
//   halo-ctl call home|shade toggle|open|close
Singleton {
    id: root

    property bool homeOpen: false
    property bool shadeOpen: false

    // Home and shade are mutually exclusive.
    function openHome() { shadeOpen = false; homeOpen = true; }
    function closeHome() { homeOpen = false; }
    function toggleHome() { if (homeOpen) closeHome(); else openHome(); }

    function openShade() { homeOpen = false; shadeOpen = true; }
    function closeShade() { shadeOpen = false; }
    function toggleShade() { if (shadeOpen) closeShade(); else openShade(); }

    IpcHandler {
        target: "home"

        function toggle(): void { root.toggleHome(); }
        function open(): void { root.openHome(); }
        function close(): void { root.closeHome(); }
    }

    IpcHandler {
        target: "shade"

        function toggle(): void { root.toggleShade(); }
        function open(): void { root.openShade(); }
        function close(): void { root.closeShade(); }
    }
}

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
    property double shadeOpenedAt: 0

    // Home and shade are mutually exclusive.
    function openHome() { shadeOpen = false; homeOpen = true; }
    function closeHome() { homeOpen = false; }
    function toggleHome() { if (homeOpen) closeHome(); else openHome(); }

    // Show the Halo desktop: close overlays and switch to the empty "home" workspace.
    function goHome() {
        homeOpen = false;
        shadeOpen = false;
        Quickshell.execDetached(["hyprctl", "eval", "go_home()"]);
    }

    function openShade() {
        if (shadeOpen)
            return;
        homeOpen = false;
        shadeOpenedAt = Date.now();
        shadeOpen = true;
    }
    function closeShade() { shadeOpen = false; }
    // Backdrop taps: ignore the touch-up that finishes the opening swipe.
    function tapCloseShade() { if (Date.now() - shadeOpenedAt > 500) closeShade(); }
    function toggleShade() { if (shadeOpen) closeShade(); else openShade(); }

    IpcHandler {
        target: "home"

        function toggle(): void { root.toggleHome(); }
        function open(): void { root.openHome(); }
        function close(): void { root.closeHome(); }
    }

    IpcHandler {
        target: "desktop"

        function show(): void { root.goHome(); }
    }

    IpcHandler {
        target: "shade"

        function toggle(): void { root.toggleShade(); }
        function open(): void { root.openShade(); }
        function close(): void { root.closeShade(); }
    }
}

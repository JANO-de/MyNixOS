pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Shared shell state + IPC entry points.
//   halo-ctl call home|shade|overview toggle|open|close ; halo-ctl call desktop show
Singleton {
    id: root

    property bool homeOpen: false
    property bool shadeOpen: false
    property double shadeOpenedAt: 0
    property bool overviewOpen: false

    // Finger-tracked pulls from the screen edges (see TopEdge.qml / BottomEdge.qml).
    property bool shadeDragging: false
    property real shadeDrag: 0 // 0..1
    property bool overviewDragging: false
    property real overviewDrag: 0 // 0..1
    property bool overviewHomeHint: false // dragged past half the screen inside an app: release = home

    // Tablet: an app is in front -> the dock and the island slide away.
    readonly property bool appOpen: Mode.tablet && ToplevelManager.activeToplevel !== null
    // No app window focused (home screen / empty workspace).
    readonly property bool onHome: ToplevelManager.activeToplevel === null
    readonly property bool chromeShown: !appOpen || homeOpen || overviewOpen || overviewDragging

    // Home and shade are mutually exclusive.
    function openHome() { shadeOpen = false; overviewOpen = false; homeOpen = true; }
    function closeHome() { homeOpen = false; }
    function toggleHome() { if (homeOpen) closeHome(); else openHome(); }

    // Show the Halo desktop: close overlays and switch to the empty "home" workspace.
    function goHome() {
        homeOpen = false;
        shadeOpen = false;
        overviewOpen = false;
        Quickshell.execDetached(["hyprctl", "eval", "go_home()"]);
    }

    function openOverview() { homeOpen = false; shadeOpen = false; overviewOpen = true; }
    function closeOverview() { overviewOpen = false; }
    function toggleOverview() { if (overviewOpen) closeOverview(); else openOverview(); }

    function openShade() {
        if (shadeOpen)
            return;
        homeOpen = false;
        overviewOpen = false;
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
        target: "overview"

        function toggle(): void { root.toggleOverview(); }
        function open(): void { root.openOverview(); }
        function close(): void { root.closeOverview(); }
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

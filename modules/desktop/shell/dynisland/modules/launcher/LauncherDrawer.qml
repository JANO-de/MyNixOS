// =============================================================================
//  LauncherDrawer — full-screen app drawer (like macOS Launchpad).
//   open: dock button, IPC `launcher toggle` (bind Mod+Space in niri), UiState.launcherOpen
//   type: fuzzy search · "2*(3+4)" calculator · "> cmd" run a command · else web search
//   keys: arrows move · Enter launches · Tab next category · Esc clears/closes
//   mouse: click an app · right-click = open / pin to dock / app actions · click empty space = close
//  The window is created when opened (LazyLoader), so every open starts fresh.
// =============================================================================
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

LazyLoader {
    active: UiState.launcherOpen

    PanelWindow {
        id: win
        // no `screen`: the compositor puts it on the focused monitor
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "dynisland-launcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        property string cat: "All"                       // All | Frequent | <category>
        property string sortMode: "auto"                 // auto (by usage) | az
        property var ctx: null                           // app whose right-click menu is open
        property real ctxX: 0
        property real ctxY: 0
        readonly property string query: search.text
        readonly property var results: Launcher.list(query, cat, sortMode)
        readonly property string calcResult: Launcher.calc(query)
        readonly property var tabs: ["All", "Frequent"].concat(Launcher.categoryNames)

        // what the extra cards below the search field do (calculator / command / web)
        readonly property var extras: {
            const q = query.trim(), out = [];
            if (!q) return out;
            if (calcResult !== "") out.push({ icon: "calculate", title: "= " + calcResult, sub: "Enter copies the result",
                                              run: () => Quickshell.execDetached(["wl-copy", calcResult]) });
            if (q.charAt(0) === ">") {
                const cmd = q.slice(1).trim();
                if (cmd) out.push({ icon: "terminal", title: "Run: " + cmd, sub: "Enter runs it in " + Config.system.terminal,
                                    // -e: run in a terminal; `exec $SHELL` keeps the window open after the command ends
                                    run: () => Quickshell.execDetached([Config.system.terminal, "-e", "sh", "-c", cmd + "; exec \"${SHELL:-sh}\""]) });
            } else out.push({ icon: "travel_explore", title: "Search the web for \u201c" + q + "\u201d", sub: "DuckDuckGo",
                              run: () => Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(q)]) });
            return out;
        }

        function close() { UiState.launcherOpen = false }
        function launch(a) { Launcher.record(a.id); a.entry.execute(); close() }
        function runExtra(x) { x.run(); close() }
        function nextTab(step) {
            const i = tabs.indexOf(cat);
            cat = tabs[(i + step + tabs.length) % tabs.length];
        }
        function openCtx(a, px, py) {   // px/py: window coordinates (the view fills the window)
            ctx = a;
            ctxX = Math.max(8, Math.min(px, win.width - 230));
            ctxY = Math.max(8, Math.min(py, win.height - 20 - 36 * (2 + Array.from(a.entry.actions || []).length)));
        }
        onResultsChanged: grid.currentIndex = 0

        Item {
            id: view
            anchors.fill: parent
            opacity: 0; scale: 1.04
            ParallelAnimation {
                running: true
                NumberAnimation { target: view; property: "opacity"; to: 1; duration: 220 }
                NumberAnimation { target: view; property: "scale"; to: 1; duration: 280; easing.type: Easing.OutCubic }
            }

            // backdrop: blurred wallpaper + dark scrim. Click on empty space closes.
            Image { id: bg; visible: false; anchors.fill: parent; asynchronous: true
                    source: Config.appearance.wallpaper ? "file://" + Config.appearance.wallpaper : ""
                    fillMode: Image.PreserveAspectCrop; sourceSize.width: win.width; sourceSize.height: win.height }
            MultiEffect { anchors.fill: parent; source: bg; blurEnabled: true; blurMax: 64; blur: 1.0; brightness: -0.2 }
            Rectangle { anchors.fill: parent; color: Theme.surface; opacity: 0.55 }
            MouseArea { anchors.fill: parent; onClicked: win.close() }

            Column {
                id: col
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 56 }
                width: Math.min(win.width * 0.82, 1180)
                spacing: 18

                // ---- search pill ----
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 560; height: 52; radius: 26
                    color: "#26ffffff"; border.width: 1
                    border.color: search.activeFocus ? Theme.primary : "#33ffffff"
                    Icon { anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter } name: "search"; size: 22; color: "#bbffffff" }
                    TextInput {
                        id: search
                        anchors { fill: parent; leftMargin: 54; rightMargin: 20 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: "white"; font.pixelSize: 18; clip: true; focus: true
                        selectionColor: Theme.primary
                        Component.onCompleted: forceActiveFocus()
                        onAccepted: {
                            if (win.results.length > 0) win.launch(win.results[Math.max(0, grid.currentIndex)]);
                            else if (win.extras.length > 0) win.runExtra(win.extras[0]);
                        }
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Escape) { if (win.ctx) win.ctx = null; else if (text !== "") text = ""; else win.close(); e.accepted = true }
                            else if (e.key === Qt.Key_Down)  { grid.moveCurrentIndexDown();  e.accepted = true }
                            else if (e.key === Qt.Key_Up)    { grid.moveCurrentIndexUp();    e.accepted = true }
                            else if (e.key === Qt.Key_Left)  { grid.moveCurrentIndexLeft();  e.accepted = true }
                            else if (e.key === Qt.Key_Right) { grid.moveCurrentIndexRight(); e.accepted = true }
                            else if (e.key === Qt.Key_Tab)     { win.nextTab(1);  e.accepted = true }
                            else if (e.key === Qt.Key_Backtab) { win.nextTab(-1); e.accepted = true }
                        }
                        Text { visible: search.text === ""; anchors.verticalCenter: parent.verticalCenter
                               text: "Search apps, calculate, or > run a command"; color: "#88ffffff"; font.pixelSize: 17 }
                    }
                }

                // ---- category chips + sort toggle (hidden while searching) ----
                Row {
                    visible: win.query === ""; anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                    Repeater {
                        model: win.tabs
                        Rectangle {
                            required property string modelData
                            readonly property bool on: win.cat === modelData
                            height: 34; width: lbl.implicitWidth + 28; radius: 17
                            color: on ? Theme.primary : (cma.containsMouse ? "#2effffff" : "#1affffff")
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text { id: lbl; anchors.centerIn: parent; text: modelData; font.pixelSize: 13
                                   color: parent.on ? Theme.primaryFg : "white" }
                            MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; onClicked: win.cat = modelData }
                        }
                    }
                    Rectangle {   // sort: Auto (most used first) / A-Z
                        visible: win.cat !== "Frequent"
                        height: 34; width: srt.implicitWidth + 28; radius: 17
                        color: sma.containsMouse ? "#2effffff" : "transparent"; border.width: 1; border.color: "#33ffffff"
                        Text { id: srt; anchors.centerIn: parent; font.pixelSize: 13; color: "#ddffffff"
                               text: win.sortMode === "auto" ? "Sort: most used" : "Sort: A\u2013Z" }
                        MouseArea { id: sma; anchors.fill: parent; hoverEnabled: true
                                    onClicked: win.sortMode = win.sortMode === "auto" ? "az" : "auto" }
                    }
                }

                // ---- extras: calculator / run / web search ----
                Column {
                    visible: win.extras.length > 0; anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                    Repeater {
                        model: win.extras
                        Rectangle {
                            required property var modelData
                            required property int index
                            width: 560; height: 52; radius: 16
                            // the first card is what Enter does when no app matches
                            color: ema.containsMouse ? "#2effffff" : (index === 0 && win.results.length === 0 ? "#26ffffff" : "#16ffffff")
                            Icon { anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter } name: modelData.icon; size: 24; color: Theme.primary }
                            Column {
                                anchors { left: parent.left; leftMargin: 56; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                                Text { width: parent.width; elide: Text.ElideRight; text: modelData.title; color: "white"; font.pixelSize: 15; font.weight: Font.Medium }
                                Text { width: parent.width; elide: Text.ElideRight; text: modelData.sub; color: "#99ffffff"; font.pixelSize: 11 }
                            }
                            MouseArea { id: ema; anchors.fill: parent; hoverEnabled: true; onClicked: win.runExtra(modelData) }
                        }
                    }
                }

                // ---- the app grid ----
                GridView {
                    id: grid
                    readonly property int cols: Math.max(3, Math.floor(width / 150))
                    width: parent.width
                    height: win.height - y - col.anchors.topMargin - 30   // fill the rest of the screen
                    cellWidth: width / cols; cellHeight: 136
                    clip: true; boundsBehavior: Flickable.StopAtBounds
                    keyNavigationEnabled: false          // keys are handled by the search field
                    model: win.results
                    currentIndex: 0
                    delegate: AppCell {
                        required property var modelData
                        required property int index
                        width: grid.cellWidth; height: grid.cellHeight
                        app: modelData
                        current: GridView.isCurrentItem
                        onHovered: grid.currentIndex = index
                        onActivated: win.launch(modelData)
                        onMenuRequested: (px, py) => win.openCtx(modelData, px, py)
                    }
                    Text { visible: win.results.length === 0 && win.extras.length === 0
                           anchors.horizontalCenter: parent.horizontalCenter; y: 40
                           text: win.cat === "Frequent" ? "Apps you launch often will show up here" : "No apps"
                           color: "#99ffffff"; font.pixelSize: 14 }
                }
            }

            // ---- right-click menu (click anywhere else closes it) ----
            MouseArea { anchors.fill: parent; z: 20; visible: win.ctx !== null
                        acceptedButtons: Qt.AllButtons; onClicked: win.ctx = null }
            Rectangle {
                id: ctxMenu
                visible: win.ctx !== null; z: 21
                x: win.ctxX; y: win.ctxY; width: 220; height: cc.height + 12; radius: 14
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.96)
                border.width: 1; border.color: "#24ffffff"
                Column {
                    id: cc; x: 6; y: 6; width: parent.width - 12
                    Repeater {
                        model: win.ctx ? [{ label: "Open", act: () => win.launch(win.ctx) },
                                          { label: Launcher.isPinned(win.ctx.id) ? "Unpin from dock" : "Pin to dock",
                                            act: () => { Launcher.togglePin(win.ctx.id); win.ctx = null } }]
                                         .concat(Array.from(win.ctx.entry.actions || []).map(ac => ({ label: ac.name, act: () => { ac.execute(); win.close() } })))
                                       : []
                        Rectangle {
                            required property var modelData
                            width: cc.width; height: 34; radius: 9
                            color: rma.containsMouse ? "#22ffffff" : "transparent"
                            Text { anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                   text: modelData.label; color: "white"; font.pixelSize: 13 }
                            MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.act() }
                        }
                    }
                }
            }
        }
    }
}

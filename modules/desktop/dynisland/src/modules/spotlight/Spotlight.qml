// =============================================================================
//  Spotlight — macOS Alt+Space style centered search bar (not the full-grid
//  app drawer in modules/launcher/, which stays as-is).
//  open: IPC `spotlight toggle` (bind to Alt+Space in niri), UiState.spotlightOpen
//  type: fuzzy app search · "2*(3+4)" calculator · "> cmd" run a command · else web search
//  keys: Up/Down move · Enter runs the selected/top result · Esc clears/closes
// =============================================================================
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

LazyLoader {
    active: UiState.spotlightOpen

    PanelWindow {
        id: win
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "dynisland-spotlight"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        readonly property string query: search.text
        readonly property var appResults: Launcher.list(query, "All", "auto").slice(0, 8)
        readonly property string calcResult: Launcher.calc(query)
        readonly property var extras: {
            const q = query.trim(), out = [];
            if (!q) return out;
            if (calcResult !== "") out.push({ icon: "calculate", title: "= " + calcResult, sub: "Enter copies the result",
                                              run: () => Quickshell.execDetached(["wl-copy", calcResult]) });
            if (q.charAt(0) === ">") {
                const cmd = q.slice(1).trim();
                if (cmd) out.push({ icon: "terminal", title: "Run: " + cmd, sub: "Enter runs it in " + Config.system.terminal,
                                    run: () => Quickshell.execDetached([Config.system.terminal, "-e", "sh", "-c", cmd + "; exec \"${SHELL:-sh}\""]) });
            } else if (appResults.length === 0) out.push({ icon: "travel_explore", title: "Search the web for \u201c" + q + "\u201d", sub: "DuckDuckGo",
                              run: () => Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(q)]) });
            return out;
        }
        readonly property var rows: appResults.map(a => ({ kind: "app", a })).concat(extras.map(x => ({ kind: "extra", x })))
        property int sel: 0
        onRowsChanged: sel = 0

        function close() { UiState.spotlightOpen = false }
        function run(row) {
            if (!row) return;
            if (row.kind === "app") { Launcher.record(row.a.id); row.a.entry.execute() }
            else row.x.run();
            close();
        }

        Item {
            anchors.fill: parent
            opacity: 0
            NumberAnimation on opacity { to: 1; duration: 150 }

            Rectangle { anchors.fill: parent; color: "#66000000" }
            MouseArea { anchors.fill: parent; onClicked: win.close() }

            Column {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.22 }
                width: 560; spacing: 8

                Rectangle {
                    width: parent.width; height: 56; radius: 28
                    color: Theme.surfaceContainer; border.width: 1; border.color: "#33ffffff"
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 1.0; shadowColor: "#80000000"; shadowVerticalOffset: 6 }
                    Icon { anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter } name: "search"; size: 22; color: "#bbffffff" }
                    TextInput {
                        id: search
                        anchors { fill: parent; leftMargin: 54; rightMargin: 20 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: "white"; font.pixelSize: 19; clip: true; focus: true
                        selectionColor: Theme.primary
                        Component.onCompleted: forceActiveFocus()
                        onAccepted: win.run(win.rows[win.sel])
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Escape) { if (text !== "") text = ""; else win.close(); e.accepted = true }
                            else if (e.key === Qt.Key_Down) { win.sel = Math.min(win.sel + 1, win.rows.length - 1); e.accepted = true }
                            else if (e.key === Qt.Key_Up)   { win.sel = Math.max(win.sel - 1, 0); e.accepted = true }
                        }
                        Text { visible: search.text === ""; anchors.verticalCenter: parent.verticalCenter
                               text: "Spotlight search"; color: "#88ffffff"; font.pixelSize: 18 }
                    }
                }

                Rectangle {
                    visible: win.rows.length > 0
                    width: parent.width; radius: 18; color: Theme.surfaceContainer; border.width: 1; border.color: "#22ffffff"
                    implicitHeight: list.contentHeight + 12
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 1.0; shadowColor: "#80000000"; shadowVerticalOffset: 6 }
                    ListView {
                        id: list
                        anchors { fill: parent; margins: 6 }
                        height: contentHeight; interactive: false
                        model: win.rows
                        delegate: Rectangle {
                            required property var modelData; required property int index
                            width: list.width; height: 48; radius: 10
                            color: index === win.sel ? Theme.primary : "transparent"
                            Row {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                spacing: 12
                                Image { anchors.verticalCenter: parent.verticalCenter; width: 28; height: 28
                                        visible: modelData.kind === "app"
                                        source: modelData.kind === "app" ? Launcher.iconFor(modelData.a.entry) : "" }
                                Icon { anchors.verticalCenter: parent.verticalCenter; visible: modelData.kind === "extra"
                                       name: modelData.kind === "extra" ? modelData.x.icon : ""; size: 22
                                       color: index === win.sel ? Theme.primaryFg : "white" }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { text: modelData.kind === "app" ? modelData.a.name : modelData.x.title
                                           color: index === win.sel ? Theme.primaryFg : "white"; font.pixelSize: 15 }
                                    Text { visible: modelData.kind === "extra"; text: modelData.kind === "extra" ? modelData.x.sub : ""
                                           color: index === win.sel ? Theme.primaryFg : "#99ffffff"; font.pixelSize: 11 }
                                }
                            }
                            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: win.sel = index; onClicked: win.run(modelData) }
                        }
                    }
                }
            }
        }
    }
}

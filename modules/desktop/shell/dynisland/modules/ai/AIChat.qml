// =============================================================================
//  AIChat — the chat panel for services/AI.qml (the agent harness).
//  Open: IPC `qs -c dynisland ipc call ai toggle` (bind a key in niri), or UiState.aiOpen.
//        `ipc call ai ask "text"` opens it and sends a message.
//  Type /help in the box for the slash commands.
// =============================================================================
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

LazyLoader {
    active: UiState.aiOpen

    PanelWindow {
        id: win
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "dynisland-ai"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        function close() { UiState.aiOpen = false }

        readonly property color dim: "#99ffffff"
        readonly property color faint: "#66ffffff"
        readonly property color bad: "#e57373"
        readonly property color good: "#81c995"
        property bool stick: true                       // keep the view pinned to the newest text

        // ---- helpers ----------------------------------------------------------------------------
        function toolIcon(name, remote) {
            if (remote) return "hub";
            switch (name) {
            case "bash": return "terminal";
            case "read_file": return "description";
            case "write_file": return "edit_document";
            case "edit_file": return "edit";
            case "list_dir": return "folder_open";
            case "web_fetch": return "language";
            case "http_request": return "http";
            case "todo_write": return "checklist";
            }
            return "api";
        }
        function clipText(s, n) { s = String(s); return s.length > n ? s.slice(0, n) + "\n…" : s }
        function describe(u) {                          // what you are being asked to allow
            const i = u.input || ({});
            switch (u.name) {
            case "bash": return "$ " + (i.command || "");
            case "write_file": return (i.path || "") + "\n" + clipText(String(i.content || "").split("\n").slice(0, 14).join("\n"), 900);
            case "edit_file": return (i.path || "") + "\n- " + clipText(i.old_string || "", 400).split("\n").join("\n- ") + "\n+ " + clipText(i.new_string || "", 400).split("\n").join("\n+ ");
            case "http_request": return (i.method || "GET") + " " + (i.url || "") + (i.headers ? "\n" + JSON.stringify(i.headers) : "") + (i.body ? "\n\n" + clipText(i.body, 600) : "");
            }
            return u.name + " " + JSON.stringify(i, null, 2);
        }
        function detail(b) {                            // expanded tool card text
            const i = b.input || ({});
            const head = b.name === "bash" ? "$ " + (i.command || "") : JSON.stringify(i, null, 2);
            return head + (b.result ? "\n\n" + clipText(b.result, 6000) : "");
        }
        function rowText(r) { return r.blocks.filter(b => b.type === "text").map(b => b.text).join("\n\n") }
        function ago(ms) {
            const s = (Date.now() - ms) / 1000;
            if (s < 90) return "now";
            if (s < 3600) return Math.round(s / 60) + " min";
            if (s < 86400) return Math.round(s / 3600) + " h";
            return Math.round(s / 86400) + " d";
        }
        function status() {
            switch (AI.phase) {
            case "wait": return "Waiting for " + (AI.modelInfo ? AI.modelInfo.id : "the model") + "…";
            case "stream": return "Writing…";
            case "tools": return AI.runningTool ? "Running tool…" : "Waiting for you…";
            case "compact": return "Summarizing the chat…";
            }
            return "";
        }
        function submit() {
            const t = input.text.trim();
            if (!t) return;
            const isCmd = /^\/[a-z]+(\s|$)/i.test(t);
            if (AI.busy && !isCmd) return;
            AI.send(t);
            input.text = "";
            win.stick = true;
        }
        function cycle(list, cur) { return list[(list.indexOf(cur) + 1) % list.length] }

        // ---- reusable bits ----------------------------------------------------------------------
        component Chip: Rectangle {
            id: chip
            property string text: ""
            property string icon: ""
            property bool active: false
            signal clicked()
            implicitHeight: 28; implicitWidth: crow.implicitWidth + 20; radius: 14
            color: active ? Theme.primary : (cma.containsMouse ? "#2effffff" : "#16ffffff")
            border.width: 1; border.color: active ? Qt.lighter(Theme.primary, 1.25) : "#1fffffff"
            Row {
                id: crow; anchors.centerIn: parent; spacing: 6
                Icon { visible: chip.icon !== ""; name: chip.icon; size: 15; color: chip.active ? Theme.primaryFg : "white"; anchors.verticalCenter: parent.verticalCenter }
                Text { text: chip.text; color: chip.active ? Theme.primaryFg : "white"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; onClicked: chip.clicked() }
        }

        component TextBlock: TextEdit {
            property var blk
            text: blk ? blk.text : ""
            readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap
            textFormat: TextEdit.MarkdownText
            color: "white"; font.pixelSize: 14
            selectionColor: Theme.primary; selectedTextColor: Theme.primaryFg
            onLinkActivated: link => Qt.openUrlExternally(link)
        }

        component ReasonBlock: Item {
            id: rb
            property var blk
            property bool manual: false
            property bool manualOpen: false
            readonly property bool open: manual ? manualOpen : (blk ? blk.open === true : false)   // live thinking is open until it ends
            visible: Config.ai.showThinking
            height: visible ? rcol.implicitHeight : 0
            Column {
                id: rcol; width: parent.width; spacing: 4
                Row {
                    spacing: 6
                    Icon { name: rb.open ? "expand_more" : "chevron_right"; size: 16; color: win.dim; anchors.verticalCenter: parent.verticalCenter }
                    Icon { name: "psychology"; size: 16; color: win.dim; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: rb.blk && rb.blk.open ? "Thinking…" : "Thoughts"; color: win.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    MouseArea { anchors.fill: parent; onClicked: { rb.manualOpen = !rb.open; rb.manual = true } }
                }
                Item {
                    visible: rb.open; width: parent.width; height: visible ? rtxt.contentHeight + 4 : 0
                    Rectangle { width: 2; height: parent.height; radius: 1; color: "#33ffffff" }
                    TextEdit {
                        id: rtxt; x: 12; width: parent.width - 12
                        text: rb.blk ? rb.blk.text : ""
                        readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap
                        color: win.dim; font.pixelSize: 13
                    }
                }
            }
        }

        component ToolBlock: Rectangle {
            id: tb
            property var blk
            property bool open: false
            height: tcol.implicitHeight + 16; radius: 12
            color: Qt.rgba(1, 1, 1, 0.045); border.width: 1; border.color: blk && blk.isError ? "#55e57373" : "#1fffffff"
            Column {
                id: tcol; x: 12; y: 8; width: parent.width - 24; spacing: 6
                Item {
                    width: parent.width; height: 22
                    Icon { id: ti; name: win.toolIcon(tb.blk ? tb.blk.name : "", tb.blk ? tb.blk.remote : false); size: 16; color: win.dim; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        id: tn; anchors { left: ti.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
                        text: tb.blk ? (tb.blk.remote && tb.blk.server ? tb.blk.server + " · " : "") + tb.blk.name : ""
                        color: "white"; font.pixelSize: 13; font.weight: Font.Medium
                    }
                    Text {
                        anchors { left: tn.right; leftMargin: 10; right: st.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        text: tb.blk ? tb.blk.summary.replace(/\n/g, " ") : ""
                        elide: Text.ElideRight; color: win.dim; font.pixelSize: 12; font.family: "monospace"
                    }
                    Icon {
                        id: st; anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        name: !tb.blk ? "" : (!tb.blk.done && !tb.blk.remote ? "progress_activity" : (tb.blk.isError ? "error" : "check_circle")); size: 16
                        color: tb.blk && tb.blk.isError ? win.bad : (tb.blk && tb.blk.done ? win.good : win.dim)
                        RotationAnimator on rotation { running: !!(tb.blk && !tb.blk.done && !tb.blk.remote); from: 0; to: 360; duration: 1100; loops: Animation.Infinite }
                    }
                    MouseArea { anchors.fill: parent; onClicked: tb.open = !tb.open }
                }
                Flickable {
                    visible: tb.open; width: parent.width; height: visible ? Math.min(260, dtxt.contentHeight + 8) : 0
                    contentHeight: dtxt.contentHeight + 8; clip: true; boundsBehavior: Flickable.StopAtBounds
                    TextEdit {
                        id: dtxt; width: parent.width
                        text: tb.blk ? win.detail(tb.blk) : ""
                        readOnly: true; selectByMouse: true; wrapMode: TextEdit.WrapAnywhere
                        color: "#ddffffff"; font.pixelSize: 12; font.family: "monospace"
                    }
                }
            }
        }

        Component {
            id: blockDelegate
            Loader {
                id: ld
                required property var modelData
                width: parent ? parent.width : 0
                sourceComponent: modelData.type === "text" ? textC : (modelData.type === "reasoning" ? reasonC : toolC)
                onLoaded: { item.blk = ld.modelData; item.width = Qt.binding(() => ld.width) }
            }
        }
        Component { id: textC; TextBlock {} }
        Component { id: reasonC; ReasonBlock {} }
        Component { id: toolC; ToolBlock {} }

        Component {
            id: rowDelegate
            Item {
                id: rd
                required property var modelData
                width: list.width
                height: rcolumn.implicitHeight
                Column {
                    id: rcolumn; width: parent.width; spacing: 8
                    Item {   // user message
                        visible: rd.modelData.kind === "user"
                        width: parent.width; height: visible ? ub.height : 0
                        Rectangle {
                            id: ub; anchors.right: parent.right
                            width: Math.min(parent.width * 0.9, tm.advanceWidth + 30); height: ut.contentHeight + 20
                            radius: 14; color: Theme.surfaceContainerHigh; border.width: 1; border.color: "#1fffffff"
                            TextMetrics { id: tm; text: rd.modelData.text || ""; font.pixelSize: 14 }
                            TextEdit {
                                id: ut; x: 15; y: 10; width: parent.width - 30
                                text: rd.modelData.text || ""
                                readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap
                                color: "white"; font.pixelSize: 14
                                selectionColor: Theme.primary; selectedTextColor: Theme.primaryFg
                            }
                        }
                    }
                    Column {   // assistant message
                        visible: rd.modelData.kind === "assistant"
                        width: parent.width; spacing: 8
                        Repeater { model: rd.modelData.kind === "assistant" ? rd.modelData.blocks : []; delegate: blockDelegate }
                        Row {
                            spacing: 8
                            Text { text: AI.rowInfo(rd.modelData); color: win.faint; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                            IconButton { diameter: 24; iconSize: 14; icon: "content_copy"; flat: true; tip: "Copy reply"; onClicked: AI.copy(win.rowText(rd.modelData)) }
                        }
                    }
                }
            }
        }

        // ---- layout -----------------------------------------------------------------------------
        Rectangle { anchors.fill: parent; color: "#66000000" }
        MouseArea { anchors.fill: parent; onClicked: win.close() }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.7, 1000); height: Math.min(parent.height * 0.88, 820)
            radius: 22; color: Theme.surfaceContainer; border.width: 1; border.color: "#33ffffff"
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 1.0; shadowColor: "#90000000"; shadowVerticalOffset: 8 }
            MouseArea { anchors.fill: parent }   // swallow clicks so they don't close

            // -------- sessions sidebar
            Rectangle {
                id: side
                visible: AI.sidebar
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: visible ? 240 : 0
                color: Qt.rgba(0, 0, 0, 0.18)
                topLeftRadius: 22; bottomLeftRadius: 22
                Column {
                    anchors { fill: parent; margins: 12 }
                    spacing: 8
                    Row {
                        width: parent.width
                        Text { text: "Chats"; color: "white"; font.pixelSize: 15; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: parent.width - 28 - 66; height: 1 }
                        IconButton { diameter: 28; iconSize: 16; icon: "add"; tip: "New chat (Ctrl+N)"; onClicked: AI.newSession() }
                    }
                    ListView {
                        width: parent.width; height: parent.height - 40
                        clip: true; spacing: 4; model: AI.sessions
                        delegate: Rectangle {
                            id: sd
                            required property var modelData
                            width: ListView.view.width; height: 50; radius: 12
                            readonly property bool cur: modelData.id === AI.sid
                            color: cur ? "#26ffffff" : (hh.hovered ? "#14ffffff" : "transparent")
                            HoverHandler { id: hh }
                            Column {
                                anchors { left: parent.left; right: del.left; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 4 }
                                Text { width: parent.width; text: sd.modelData.title; elide: Text.ElideRight; color: "white"; font.pixelSize: 13 }
                                Text { width: parent.width; text: win.ago(sd.modelData.updated) + " · " + sd.modelData.model; elide: Text.ElideRight; color: win.faint; font.pixelSize: 11 }
                            }
                            MouseArea { id: sma; anchors.fill: parent; hoverEnabled: true; onClicked: AI.openSession(sd.modelData.id) }
                            IconButton {
                                id: del; anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                                opacity: hh.hovered ? 1 : 0
                                diameter: 26; iconSize: 14; icon: "delete"; flat: true; tip: "Delete chat"
                                onClicked: AI.deleteSession(sd.modelData.id)
                            }
                        }
                    }
                }
            }

            // -------- main column
            ColumnLayout {
                id: main
                anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 16 }
                spacing: 10

                // header
                Item {
                    Layout.fillWidth: true; implicitHeight: 32
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 8
                        IconButton { diameter: 30; iconSize: 17; icon: "menu"; flat: true; active: AI.sidebar; tip: "Chats"; onClicked: AI.sidebar = !AI.sidebar }
                        Text { text: AI.title || "New chat"; color: "white"; font.pixelSize: 15; font.bold: true; width: Math.max(60, main.width - 560); elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 6
                        Chip {
                            icon: "smart_toy"; active: AI.picker !== ""
                            text: (AI.provider ? (AI.provider.name || AI.provider.id) : "no provider") + " · " + Config.ai.model
                            onClicked: AI.picker = AI.picker === "" ? "model" : ""
                        }
                        Chip {
                            icon: "psychology"; text: "think: " + Config.ai.thinking; active: Config.ai.thinking !== "off"
                            onClicked: Config.ai.thinking = win.cycle(["off", "low", "medium", "high"], Config.ai.thinking)
                        }
                        Chip {
                            icon: Config.ai.approve === "auto" ? "bolt" : "shield"; text: "tools: " + Config.ai.approve
                            onClicked: Config.ai.approve = win.cycle(["ask", "edits", "auto"], Config.ai.approve)
                        }
                        IconButton { diameter: 28; iconSize: 16; icon: "compress"; tip: "Compact: summarize the chat to free context"; onClicked: AI.compact() }
                        IconButton { diameter: 28; iconSize: 16; icon: "add"; tip: "New chat (Ctrl+N)"; onClicked: AI.newSession() }
                        IconButton { diameter: 28; iconSize: 16; icon: "close"; onClicked: win.close() }
                    }
                }

                // model / provider picker
                Rectangle {
                    visible: AI.picker !== ""
                    Layout.fillWidth: true; implicitHeight: Math.min(300, pcol.implicitHeight + 24)
                    radius: 14; color: Theme.surfaceContainerHigh; border.width: 1; border.color: "#22ffffff"; clip: true
                    Column {
                        id: pcol; x: 12; y: 12; width: parent.width - 24; spacing: 8
                        Row {
                            visible: AI.providers.length > 1; spacing: 6
                            Repeater {
                                model: AI.providers
                                delegate: Chip {
                                    required property var modelData
                                    text: modelData.name || modelData.id; active: !!AI.provider && modelData.id === AI.provider.id
                                    onClicked: AI.setProvider(modelData.id)
                                }
                            }
                        }
                        ListView {
                            width: parent.width; height: Math.min(150, contentHeight); clip: true; spacing: 2
                            model: AI.modelList
                            delegate: Rectangle {
                                id: md
                                required property string modelData
                                width: ListView.view.width; height: 30; radius: 8
                                color: modelData === Config.ai.model ? Theme.primary : (mma.containsMouse ? "#22ffffff" : "transparent")
                                Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: md.modelData; font.pixelSize: 13
                                       color: md.modelData === Config.ai.model ? Theme.primaryFg : "white" }
                                MouseArea { id: mma; anchors.fill: parent; hoverEnabled: true; onClicked: AI.setModel(md.modelData) }
                            }
                        }
                        Text { visible: AI.modelList.length === 0; text: "No models listed. Type an id below, or add \"models\" to this provider in ai.json."; color: win.dim; font.pixelSize: 12; width: parent.width; wrapMode: Text.Wrap }
                        Field { width: parent.width; placeholder: "other model id, then Enter"; onAccepted: t => { if (t.trim()) { AI.setModel(t.trim()); text = "" } } }
                    }
                }

                // task list from todo_write
                Rectangle {
                    visible: AI.todos.length > 0
                    Layout.fillWidth: true; implicitHeight: tcolm.implicitHeight + 18
                    radius: 14; color: Qt.rgba(1, 1, 1, 0.045); border.width: 1; border.color: "#1fffffff"
                    Column {
                        id: tcolm; x: 14; y: 9; width: parent.width - 28; spacing: 3
                        Repeater {
                            model: AI.todos
                            delegate: Row {
                                required property var modelData
                                spacing: 8
                                Icon { name: modelData.status === "completed" ? "check_circle" : (modelData.status === "in_progress" ? "arrow_circle_right" : "radio_button_unchecked"); size: 16
                                       color: modelData.status === "completed" ? win.good : (modelData.status === "in_progress" ? Theme.primary : win.faint); anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.content; font.pixelSize: 13; width: tcolm.width - 30; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter
                                       color: modelData.status === "completed" ? win.faint : "white"; font.strikeout: modelData.status === "completed" }
                            }
                        }
                    }
                }

                // conversation
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    radius: 14; color: Theme.surfaceContainerHigh
                    ListView {
                        id: list
                        anchors { fill: parent; margins: 12 }
                        clip: true; spacing: 16
                        model: AI.rows
                        delegate: rowDelegate
                        boundsBehavior: Flickable.StopAtBounds
                        onCountChanged: positionViewAtEnd()
                        onContentHeightChanged: if (win.stick) positionViewAtEnd()
                        onMovementStarted: win.stick = false
                        onAtYEndChanged: if (atYEnd) win.stick = true
                        header: Item {   // empty state
                            width: list.width; height: AI.rows.length === 0 && !AI.busy ? 150 : 0
                            visible: height > 0
                            Column {
                                anchors.centerIn: parent; spacing: 6
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Ask anything, or give me a task."; color: "white"; font.pixelSize: 16 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; color: win.dim; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter
                                       text: (AI.provider ? (AI.provider.name || AI.provider.id) : "No provider") + " · " + Config.ai.model + "\nI can run commands and edit files (you approve). Type / for commands." }
                            }
                        }
                        footer: Column {
                            width: list.width; spacing: 10; topPadding: AI.liveBlocks.length || AI.busy || AI.pending ? 10 : 0
                            Repeater { model: AI.liveBlocks; delegate: blockDelegate }
                            Row {
                                visible: AI.busy && !AI.pending; spacing: 8
                                Icon { name: "progress_activity"; size: 16; color: win.dim; anchors.verticalCenter: parent.verticalCenter
                                       RotationAnimator on rotation { running: AI.busy; from: 0; to: 360; duration: 1100; loops: Animation.Infinite } }
                                Text { text: win.status(); color: win.dim; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Rectangle {   // approval card
                                visible: AI.pending !== null
                                width: parent.width; height: visible ? acol.implicitHeight + 24 : 0
                                radius: 14; color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12); border.width: 1; border.color: Theme.primary
                                Column {
                                    id: acol; x: 14; y: 12; width: parent.width - 28; spacing: 8
                                    Row {
                                        spacing: 8
                                        Icon { name: AI.pending ? win.toolIcon(AI.pending.tool.name, false) : ""; size: 18; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                                        Text { text: AI.pending ? "Allow " + AI.pending.tool.name + "?" : ""; color: "white"; font.pixelSize: 14; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                    Rectangle {
                                        width: parent.width; height: Math.min(180, atxt.contentHeight + 16); radius: 10; color: Qt.rgba(0, 0, 0, 0.3); clip: true
                                        Flickable {
                                            anchors { fill: parent; margins: 8 }
                                            contentHeight: atxt.contentHeight; clip: true; boundsBehavior: Flickable.StopAtBounds
                                            TextEdit {
                                                id: atxt; width: parent.width
                                                text: AI.pending ? win.describe(AI.pending.use) : ""
                                                readOnly: true; selectByMouse: true; wrapMode: TextEdit.WrapAnywhere
                                                color: "#eeffffff"; font.pixelSize: 12; font.family: "monospace"
                                            }
                                        }
                                    }
                                    Row {
                                        spacing: 8
                                        PillButton { implicitHeight: 34; label: "Allow"; icon: "check_circle"; filled: true; onClicked: AI.approve(false) }
                                        PillButton { implicitHeight: 34; label: "Always allow " + (AI.pending ? AI.pending.tool.name : ""); onClicked: AI.approve(true) }
                                        PillButton { implicitHeight: 34; label: "Deny"; icon: "close"; onClicked: AI.deny() }
                                    }
                                }
                            }
                        }
                    }
                }

                // banners: errors, info, compact hint
                Column {
                    id: banners
                    Layout.fillWidth: true; spacing: 6
                    Rectangle {
                        visible: AI.error !== ""
                        width: parent.width; height: visible ? etxt.contentHeight + 16 : 0; radius: 10; color: "#33e57373"
                        TextEdit { id: etxt; x: 12; y: 8; width: parent.width - 48; text: AI.error; readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap; color: "#ffcdd2"; font.pixelSize: 12 }
                        IconButton { anchors { right: parent.right; top: parent.top; margins: 4 } diameter: 24; iconSize: 14; icon: "close"; flat: true; onClicked: AI.error = "" }
                    }
                    Rectangle {
                        visible: AI.info !== ""
                        width: parent.width; height: visible ? Math.min(160, itxt.contentHeight + 16) : 0; radius: 10; color: "#1fffffff"; clip: true
                        Flickable {
                            x: 12; y: 8; width: parent.width - 48; height: parent.height - 16; contentHeight: itxt.contentHeight; clip: true; boundsBehavior: Flickable.StopAtBounds
                            TextEdit { id: itxt; width: parent.width; text: AI.info; readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap; color: "#ddffffff"; font.pixelSize: 12 }
                        }
                        IconButton { anchors { right: parent.right; top: parent.top; margins: 4 } diameter: 24; iconSize: 14; icon: "close"; flat: true; onClicked: AI.info = "" }
                    }
                }

                // slash-command suggestions
                Flow {
                    id: sugg
                    Layout.fillWidth: true; spacing: 6
                    readonly property var matches: input.text.indexOf("/") === 0 && input.text.indexOf(" ") < 0
                        ? AI.commandList.filter(c => c.c.indexOf(input.text.toLowerCase()) === 0) : []
                    Layout.preferredHeight: childrenRect.height
                    visible: matches.length > 0
                    Repeater {
                        model: sugg.matches
                        delegate: Chip { required property var modelData; text: modelData.c + "  " + modelData.d; onClicked: { input.text = modelData.c + " "; input.forceActiveFocus(); input.cursorPosition = input.text.length } }
                    }
                }

                // input
                Rectangle {
                    id: inputBox
                    Layout.fillWidth: true; implicitHeight: Math.max(48, Math.min(150, input.contentHeight + 26)); radius: 24
                    color: Theme.surfaceContainerHigh; border.width: 1; border.color: input.activeFocus ? Theme.primary : "#22ffffff"
                    Flickable {
                        anchors { fill: parent; leftMargin: 18; rightMargin: 54; topMargin: 13; bottomMargin: 13 }
                        contentHeight: input.contentHeight; clip: true; boundsBehavior: Flickable.StopAtBounds
                        TextEdit {
                            id: input
                            width: parent.width
                            color: "white"; font.pixelSize: 14; wrapMode: TextEdit.Wrap; selectByMouse: true
                            selectionColor: Theme.primary; selectedTextColor: Theme.primaryFg
                            Component.onCompleted: forceActiveFocus()
                            Keys.onPressed: e => {
                                if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && !(e.modifiers & Qt.ShiftModifier)) { win.submit(); e.accepted = true }
                                else if (e.key === Qt.Key_Escape) { if (AI.picker !== "") AI.picker = ""; else if (AI.busy) AI.stop(); else win.close(); e.accepted = true }
                                else if (e.key === Qt.Key_N && (e.modifiers & Qt.ControlModifier)) { AI.newSession(); e.accepted = true }
                                else if (e.key === Qt.Key_B && (e.modifiers & Qt.ControlModifier)) { AI.sidebar = !AI.sidebar; e.accepted = true }
                            }
                            Text {
                                visible: input.text === ""; anchors.top: parent.top
                                text: AI.provider && AI.provider.kind === "anthropic" && !AI.hasKey(AI.provider) ? "Set an API key in Settings > AI" : "Message… (Enter sends, Shift+Enter new line, / for commands)"
                                color: "#77ffffff"; font.pixelSize: 14
                            }
                        }
                    }
                    IconButton {
                        anchors { right: parent.right; rightMargin: 7; verticalCenter: parent.verticalCenter }
                        diameter: 36; iconSize: 18; active: true
                        icon: AI.busy ? "stop_circle" : "send"; tip: AI.busy ? "Stop (Esc)" : "Send"
                        onClicked: AI.busy ? AI.stop() : win.submit()
                    }
                }

                // usage: context bar, tokens, cost, rate limits
                Item {
                    id: usageRow
                    Layout.fillWidth: true; implicitHeight: 18
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 10
                        Rectangle {
                            width: 80; height: 6; radius: 3; color: "#22ffffff"; anchors.verticalCenter: parent.verticalCenter
                            Rectangle { width: parent.width * AI.ctxFrac; height: parent.height; radius: 3
                                        color: AI.ctxFrac > 0.9 ? win.bad : (AI.ctxFrac > 0.7 ? "#ffb74d" : Theme.primary) }
                        }
                        Text { text: "context " + AI.fmtTok(AI.ctxUsed) + (AI.ctxMax ? " / " + AI.fmtTok(AI.ctxMax) : ""); color: win.dim; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: AI.usageLine(); color: win.faint; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        Text { visible: AI.limitsLine() !== ""; text: "limits " + AI.limitsLine(); color: win.faint; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        Chip { visible: AI.ctxFrac > 0.8 && !AI.busy; height: 18; implicitHeight: 18; text: "compact"; onClicked: AI.compact() }
                    }
                }
            }
        }
    }
}

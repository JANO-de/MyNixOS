// Monitor Manager — shared UI body.
//
// Used both as a standalone window (MonitorManager.qml) and as a page inside
// the iNiR settings (MonitorManagerConfig.qml). Deliberately imports nothing
// from the iNiR QML tree, so the standalone window resolves outside the shell
// runtime dir where `qs.*` modules are not importable.
//
// Backend contract (scripts/monitor-manager.py):
//   outputs                      -> [{ name, current_resolution, scale, ... }]
//   persist-layout <json>        -> all output positions, validated + reloaded
//   persist-output NAME k=v      -> one key, validated + reloaded
//   profile save|list|load|delete
//   clear                        -> drop every managed override
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Colour roles. Neutral dark defaults so the standalone window works
    // without the shell; MonitorManagerConfig.qml binds these to the iNiR
    // Appearance palette so the settings page matches the surrounding UI.
    property MonitorManagerTheme theme: MonitorManagerTheme {}

    // Backend script. The wrapper exports MONITOR_MANAGER_PY; inside the iNiR
    // runtime dir the bundled copy is found relative to the shell root.
    readonly property string backendScript: {
        const fromEnv = Quickshell.env("MONITOR_MANAGER_PY")
        if (fromEnv)
            return fromEnv
        const bundled = Quickshell.shellPath("scripts/monitor-manager.py")
        if (bundled && bundled !== "")
            return bundled
        return "monitor-manager"
    }

    property var outputs: []
    property var profiles: []
    property string selectedName: ""
    property string statusText: ""
    property bool statusIsError: false
    property string pendingSuccessText: ""
    readonly property bool busy: actionProcess.running || outputsProcess.running
    property string profileName: ""

    readonly property var selectedOutput: outputByName(root.selectedName)

    function backend(...args) {
        return ["python3", root.backendScript, ...args]
    }

    function parse(text, what) {
        let data
        try {
            data = JSON.parse(text)
        } catch (err) {
            root.setStatus(what + ": backend returned invalid JSON", true)
            return null
        }
        if (data && !Array.isArray(data) && data.error) {
            root.setStatus(String(data.error), true)
            return null
        }
        return data
    }

    function setStatus(text, isError) {
        root.statusText = text
        root.statusIsError = isError === true
    }

    function outputByName(name) {
        if (!name)
            return null
        for (let i = 0; i < root.outputs.length; i++) {
            if (root.outputs[i].name === name)
                return root.outputs[i]
        }
        return null
    }

    function refresh() {
        if (root.outputs.length > 0 && root.outputByName(root.selectedName) === null)
            root.selectedName = ""
        outputsProcess.running = true
        profilesProcess.running = true
    }

    // Run a mutating backend command, then re-read state.
    //
    // Only one backend call can be in flight, so a second request is refused
    // loudly rather than dropped: silently ignoring it would leave the UI
    // showing a change that never happened.
    function run(command, successText) {
        if (root.busy) {
            root.setStatus("Another change is still being applied — try again in a moment.", true)
            return
        }
        actionProcess.command = command
        actionProcess.successText = successText
        actionProcess.running = true
    }

    function runProfile(args, successText) {
        root.run(root.backend("profile", ...args), successText)
    }

    // ── Geometry ──────────────────────────────────────────────────────

    // Logical pixel size of an output, used only to draw the canvas.
    function sizeOf(output) {
        if (output.logical_size && output.logical_size[0] > 0)
            return output.logical_size
        if (output.current_resolution) {
            const parts = output.current_resolution.split("x")
            return [parseInt(parts[0]) || 1920, parseInt(parts[1]) || 1080]
        }
        if (output.physical_size && output.physical_size[0] > 0) {
            const s = output.scale || 1
            return [Math.round(output.physical_size[0] / s), Math.round(output.physical_size[1] / s)]
        }
        return [1920, 1080]
    }

    // Outputs niri has actually mapped. A connected output that is switched
    // off reports no logical output, so it has no place in the layout and must
    // not be drawn on top of the others at the origin.
    readonly property var placedOutputs: {
        const placed = []
        for (let i = 0; i < root.outputs.length; i++) {
            if (root.outputs[i].enabled !== false)
                placed.push(root.outputs[i])
        }
        return placed
    }

    // Bounding box of every mapped output in niri's global logical space.
    readonly property rect logicalBounds: {
        const placed = root.placedOutputs
        if (placed.length === 0)
            return Qt.rect(0, 0, 1920, 1080)
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
        for (let i = 0; i < placed.length; i++) {
            const o = placed[i]
            const size = root.sizeOf(o)
            const x = o.position ? o.position.x : 0
            const y = o.position ? o.position.y : 0
            minX = Math.min(minX, x)
            minY = Math.min(minY, y)
            maxX = Math.max(maxX, x + size[0])
            maxY = Math.max(maxY, y + size[1])
        }
        return Qt.rect(minX, minY, Math.max(maxX - minX, 1), Math.max(maxY - minY, 1))
    }

    readonly property real pxPerLogical: {
        if (root.placedOutputs.length === 0 || canvas.width <= 0 || canvas.height <= 0)
            return 0.25
        const pad = 24
        const byWidth = (canvas.width - pad * 2) / root.logicalBounds.width
        const byHeight = (canvas.height - pad * 2) / root.logicalBounds.height
        return Math.max(Math.min(byWidth, byHeight), 0.02)
    }

    function snap(value) {
        return Math.round(value / 10) * 10
    }

    // Map a point in niri's global logical space to canvas pixels. The
    // bounding box origin is normalized away, so a layout that hangs off the
    // origin (negative x or y) still draws inside the canvas.
    function canvasPoint(logicalX, logicalY) {
        return {
            x: (logicalX - root.logicalBounds.x) * root.pxPerLogical + 12,
            y: (logicalY - root.logicalBounds.y) * root.pxPerLogical + 12
        }
    }

    // ── Mutations ─────────────────────────────────────────────────────

    function persistPosition(name, x, y) {
        const layout = {}
        for (let i = 0; i < root.outputs.length; i++) {
            const o = root.outputs[i]
            if (o.name === name)
                layout[o.name] = { x: x, y: y }
            else
                layout[o.name] = { x: o.position.x, y: o.position.y }
        }
        // Update locally first so the drag does not snap back.
        const updated = []
        for (let i = 0; i < root.outputs.length; i++) {
            const o = root.outputs[i]
            if (o.name === name) {
                o.position = { x: x, y: y }
            }
            updated.push(o)
        }
        root.outputs = updated
        root.run(root.backend("persist-layout", JSON.stringify(layout)),
                 "Layout saved to config.d/15-outputs.kdl")
    }

    function persistKey(name, key, value) {
        root.run(root.backend("persist-output", name, key + "=" + value),
                 name + ": " + key + " = " + value)
    }

    // ── Backend processes ─────────────────────────────────────────────

    Process {
        id: outputsProcess
        command: root.backend("outputs")
        stdout: StdioCollector {
            onStreamFinished: {
                const data = root.parse(text, "outputs")
                if (data) {
                    root.outputs = data
                    if (root.selectedName === "")
                        root.selectedName = data.length > 0 ? data[0].name : ""
                    // A completed change reports its own outcome; the refresh
                    // triggered by that change must not overwrite the message.
                    if (root.pendingSuccessText !== "") {
                        root.setStatus(root.pendingSuccessText, false)
                        root.pendingSuccessText = ""
                    } else {
                        root.setStatus(root.outputs.length + " output(s) connected", false)
                    }
                }
            }
        }
        stderr: StdioCollector { id: outputsErr }
        onExited: (code) => {
            if (code !== 0)
                root.setStatus((outputsErr.text || "niri msg failed").trim(), true)
        }
    }

    Process {
        id: profilesProcess
        command: root.backend("profile", "list")
        stdout: StdioCollector {
            onStreamFinished: {
                const data = root.parse(text, "profile list")
                if (data)
                    root.profiles = data
            }
        }
    }

    Process {
        id: actionProcess
        property string successText: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const data = root.parse(text, "action")
                if (data) {
                    // Hand the message to the refresh that follows, so it
                    // survives the state reload.
                    root.pendingSuccessText = actionProcess.successText
                    outputsProcess.running = true
                    profilesProcess.running = true
                }
            }
        }
        stderr: StdioCollector { id: actionErr }
        onExited: (code) => {
            if (code !== 0) {
                root.pendingSuccessText = ""
                root.setStatus((actionErr.text || "backend failed").trim(), true)
            }
        }
    }

    Component.onCompleted: root.refresh()

    // ── Layout ────────────────────────────────────────────────────────

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: "Monitor Manager"
                font.pointSize: 15
                font.bold: true
                color: root.theme.accent
            }

            Label {
                text: "Drag screens to rearrange. Changes are validated and applied to niri immediately."
                color: root.theme.subtext
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Button {
                text: "Auto-arrange"
                enabled: !root.busy && root.placedOutputs.length > 1
                onClicked: {
                    // Only the mapped outputs are arranged and persisted: giving
                    // a position to a switched-off output would bring it back
                    // up, which the user did not ask for here.
                    const placed = root.placedOutputs
                    const layout = {}
                    let x = 0
                    for (let i = 0; i < placed.length; i++) {
                        const o = placed[i]
                        layout[o.name] = { x: x, y: 0 }
                        x += root.sizeOf(o)[0]
                    }
                    const positions = {}
                    for (const name in layout)
                        positions[name] = layout[name]
                    const updated = root.outputs.map((o) => {
                        if (positions[o.name]) {
                            o.position = { x: positions[o.name].x, y: positions[o.name].y }
                        }
                        return o
                    })
                    root.outputs = updated
                    root.run(root.backend("persist-layout", JSON.stringify(positions)),
                             "Auto-arranged " + placed.length + " output(s)")
                }
            }

            Button {
                text: "Refresh"
                enabled: !root.busy
                onClicked: root.refresh()
            }

            Button {
                text: "Clear all overrides"
                enabled: !root.busy
                onClicked: {
                    confirmClear.open()
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: root.statusText !== ""
            text: root.statusText
            color: root.statusIsError ? root.theme.error : root.theme.subtext
            wrapMode: Text.WordWrap
        }

        // ── Drag surface ────────────────────────────────────────────
        Rectangle {
            id: canvas
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 220
            radius: 8
            color: root.theme.background
            border.color: root.theme.outline
            clip: true

            Label {
                anchors.centerIn: parent
                visible: root.outputs.length === 0
                text: root.busy ? "Querying outputs…" : "No outputs reported by niri."
                color: root.theme.subtext
            }

            Repeater {
                id: monitorRepeater
                model: root.placedOutputs

                delegate: Rectangle {
                    id: monitorTile
                    required property var modelData

                    readonly property var data_: modelData
                    readonly property var size_: root.sizeOf(monitorTile.data_)
                    readonly property bool selected: monitorTile.data_.name === root.selectedName

                    readonly property point origin: root.canvasPoint(
                        monitorTile.data_.position ? monitorTile.data_.position.x : 0,
                        monitorTile.data_.position ? monitorTile.data_.position.y : 0)

                    // Drag preview offsets in canvas pixels. Kept out of the
                    // model on purpose: writing to the model mid-drag would
                    // rebuild this delegate and cancel the gesture.
                    property real dragOffsetX: 0
                    property real dragOffsetY: 0

                    x: monitorTile.origin.x + monitorTile.dragOffsetX
                    y: monitorTile.origin.y + monitorTile.dragOffsetY
                    width: Math.max(monitorTile.size_[0] * root.pxPerLogical, 70)
                    height: Math.max(monitorTile.size_[1] * root.pxPerLogical, 40)
                    radius: 6
                    color: monitorTile.selected ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.28)
                                    : root.theme.surface
                    border.color: monitorTile.selected ? root.theme.accent : root.theme.outline
                    border.width: monitorTile.selected ? 2 : 1
                    scale: dragArea.pressed ? 0.98 : 1
                    Behavior on scale { NumberAnimation { duration: 90 } }

                    Label {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        color: root.theme.fg
                        text: monitorTile.data_.name
                              + "\n" + (monitorTile.data_.current_resolution || "?")
                              + " @ " + (monitorTile.data_.current_rate_string || "?")
                              + "\nx " + monitorTile.liveX + ", y " + monitorTile.liveY
                    }

                    // Live position readout while dragging.
                    readonly property int liveX: root.pxPerLogical > 0
                        ? root.snap((data_.position ? data_.position.x : 0) + monitorTile.dragOffsetX / root.pxPerLogical)
                        : (data_.position ? data_.position.x : 0)
                    readonly property int liveY: root.pxPerLogical > 0
                        ? root.snap((data_.position ? data_.position.y : 0) + monitorTile.dragOffsetY / root.pxPerLogical)
                        : (data_.position ? data_.position.y : 0)

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor
                        preventStealing: true

                        // Where the gesture started, expressed in the canvas's
                        // coordinate system rather than this MouseArea's.
                        //
                        // This has to be canvas-relative. The MouseArea lives
                        // inside the tile and the tile is what the drag moves,
                        // so mouse coordinates here shift every time the
                        // offset below changes. Measuring the delta against
                        // them makes each event subtract the previous
                        // movement, which sends the tile to the opposite side
                        // of the layout and accelerates from there.
                        property point grabCanvas: Qt.point(0, 0)

                        // Pointer position in canvas coordinates.
                        function pointerInCanvas(mouse) {
                            return dragArea.mapToItem(canvas, mouse.x, mouse.y)
                        }

                        onPressed: (mouse) => {
                            root.selectedName = monitorTile.data_.name
                            grabCanvas = pointerInCanvas(mouse)
                            monitorTile.dragOffsetX = 0
                            monitorTile.dragOffsetY = 0
                        }

                        onPositionChanged: (mouse) => {
                            if (!pressed || root.pxPerLogical <= 0)
                                return
                            // Snap the preview to the 10px grid, then feed the
                            // snapped delta back so the tile never sits between
                            // grid lines.
                            const now = pointerInCanvas(mouse)
                            const rawX = now.x - dragArea.grabCanvas.x
                            const rawY = now.y - dragArea.grabCanvas.y
                            const stepX = root.snap(rawX / root.pxPerLogical) * root.pxPerLogical - rawX
                            const stepY = root.snap(rawY / root.pxPerLogical) * root.pxPerLogical - rawY
                            monitorTile.dragOffsetX = rawX + stepX
                            monitorTile.dragOffsetY = rawY + stepY
                        }

                        onReleased: {
                            if (root.pxPerLogical <= 0)
                                return
                            const targetX = monitorTile.liveX
                            const targetY = monitorTile.liveY
                            monitorTile.dragOffsetX = 0
                            monitorTile.dragOffsetY = 0
                            if (targetX === (monitorTile.data_.position ? monitorTile.data_.position.x : 0)
                                && targetY === (monitorTile.data_.position ? monitorTile.data_.position.y : 0))
                                return
                            root.persistPosition(monitorTile.data_.name, targetX, targetY)
                        }
                    }
                }
            }
        }

        // ── Per-output controls ─────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: controlsColumn.implicitHeight + 24
            radius: 8
            color: root.theme.surface
            border.color: root.theme.outline

            ColumnLayout {
                id: controlsColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Label {
                    text: root.selectedOutput
                          ? root.selectedOutput.name + " — " + (root.selectedOutput.model || root.selectedOutput.make || "output")
                          : "No output selected"
                    font.bold: true
                    color: root.theme.fg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ComboBox {
                        id: resolutionCombo
                        Layout.fillWidth: true
                        enabled: root.selectedOutput !== null && !root.busy
                        textRole: "label"
                        model: {
                            if (!root.selectedOutput)
                                return []
                            return root.selectedOutput.resolutions.map((r) => ({
                                label: r.width + "x" + r.height,
                                key: r.width + "x" + r.height,
                                resolution: r
                            }))
                        }
                        onActivated: {
                            const entry = model[currentIndex]
                            if (!entry || !root.selectedOutput)
                                return
                            const rates = entry.resolution.rates.slice().sort((a, b) => b.rate - a.rate)
                            const best = entry.resolution.preferred && entry.resolution.rates.length
                                    ? entry.resolution.rates.find((r) => r.preferred) || rates[0]
                                    : rates[0]
                            if (best)
                                root.persistKey(root.selectedName, "mode", entry.key + "@" + best.rate_string)
                        }
                    }

                    ComboBox {
                        id: refreshCombo
                        Layout.fillWidth: true
                        enabled: root.selectedOutput !== null && !root.busy
                        textRole: "label"
                        model: {
                            if (!root.selectedOutput)
                                return []
                            const current = root.selectedOutput.current_resolution
                            const entry = root.selectedOutput.resolutions.find((r) => r.width + "x" + r.height === current)
                            if (!entry)
                                return []
                            return entry.rates.map((r) => ({
                                label: r.rate_string + " Hz" + (r.preferred ? "  (preferred)" : ""),
                                key: r.rate_string
                            }))
                        }
                        onActivated: {
                            const entry = model[currentIndex]
                            if (entry)
                                root.persistKey(root.selectedName, "mode",
                                                root.selectedOutput.current_resolution + "@" + entry.key)
                        }
                    }

                    ComboBox {
                        id: scaleCombo
                        Layout.fillWidth: true
                        enabled: root.selectedOutput !== null && !root.busy
                        textRole: "label"
                        model: {
                            const values = [0.5, 0.65, 0.75, 0.9, 1, 1.1, 1.25, 1.5, 1.75, 2, 2.5, 3]
                            if (root.selectedOutput) {
                                const current = Number(root.selectedOutput.scale)
                                if (!values.includes(current))
                                    values.push(current)
                                values.sort((a, b) => a - b)
                            }
                            return values.map((v) => ({ label: v + "x", key: v }))
                        }
                        onActivated: {
                            const entry = model[currentIndex]
                            if (entry)
                                root.persistKey(root.selectedName, "scale", String(entry.key))
                        }
                    }

                    ComboBox {
                        id: transformCombo
                        Layout.fillWidth: true
                        enabled: root.selectedOutput !== null && !root.busy
                        textRole: "label"
                        model: ["Normal", "90", "180", "270", "Flipped", "Flipped90", "Flipped180", "Flipped270"]
                            .map((v) => ({ label: v, key: v }))
                        onActivated: {
                            const entry = model[currentIndex]
                            if (entry)
                                root.persistKey(root.selectedName, "transform", entry.key)
                        }
                    }

                    ComboBox {
                        id: vrrCombo
                        Layout.fillWidth: true
                        visible: root.selectedOutput !== null && root.selectedOutput.vrr_supported
                        enabled: root.selectedOutput !== null && !root.busy
                        textRole: "label"
                        model: [
                            { label: "VRR off", key: "off" },
                            { label: "VRR always", key: "on" },
                            { label: "VRR on demand", key: "on-demand" }
                        ]
                        onActivated: {
                            const entry = model[currentIndex]
                            if (entry)
                                root.persistKey(root.selectedName, "vrr", entry.key)
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    visible: root.selectedOutput !== null
                    text: root.selectedOutput
                          ? "Position " + (root.selectedOutput.position ? root.selectedOutput.position.x : 0)
                            + ", " + (root.selectedOutput.position ? root.selectedOutput.position.y : 0)
                            + "   •   VRR " + (root.selectedOutput.vrr_mode || "off")
                            + "   •   written to ~/.config/niri/config.d/15-outputs.kdl"
                          : ""
                    color: root.theme.subtext
                    elide: Text.ElideRight
                    font.pixelSize: 12
                }
            }
        }

        // ── Profile configurator ────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(profileList.contentHeight + 100, 150)
            radius: 8
            color: root.theme.surface
            border.color: root.theme.outline

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: "Monitor configurations"
                        font.bold: true
                        color: root.theme.fg
                    }

                    Label {
                        text: "A profile snapshots every connected output. Loading one writes it to the config and reloads niri."
                        color: root.theme.subtext
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    TextField {
                        id: profileNameField
                        Layout.preferredWidth: 200
                        placeholderText: "Profile name"
                        enabled: !root.busy
                        onAccepted: root.saveProfile()
                    }

                    Button {
                        text: "Save current"
                        enabled: !root.busy && profileNameField.text.trim() !== ""
                        onClicked: root.saveProfile()
                    }
                }

                ListView {
                    id: profileList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: root.profiles

                    delegate: Rectangle {
                        id: profileRow
                        required property var modelData
                        width: profileList.width
                        height: 44
                        radius: 6
                        color: hover.hovered ? root.theme.background : "transparent"
                        border.color: root.theme.outline

                        HoverHandler { id: hover }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            spacing: 0

                            Label {
                                text: profileRow.modelData.name
                                color: root.theme.fg
                                font.bold: true
                            }
                            Label {
                                text: profileRow.modelData.outputs.join(", ")
                                color: root.theme.subtext
                                font.pixelSize: 11
                            }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            spacing: 6

                            Button {
                                text: "Load"
                                enabled: !root.busy
                                onClicked: root.runProfile(["load", profileRow.modelData.name],
                                                             "Loaded profile “" + profileRow.modelData.name + "”")
                            }

                            Button {
                                text: "Delete"
                                enabled: !root.busy
                                onClicked: root.runProfile(["delete", profileRow.modelData.name],
                                                             "Deleted profile “" + profileRow.modelData.name + "”")
                            }
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    visible: root.profiles.length === 0
                    text: "No saved configurations yet. Arrange the screens, then save them as a profile."
                    color: root.theme.subtext
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    function saveProfile() {
        const name = profileNameField.text.trim()
        if (name === "")
            return
        root.runProfile(["save", name], "Saved profile “" + name + "”")
        profileNameField.text = ""
    }

    Dialog {
        id: confirmClear
        title: "Clear all monitor overrides?"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            root.setStatus("Overrides cleared; niri auto-places outputs again", false)
            root.run(root.backend("clear"), "Cleared config.d/15-outputs.kdl")
        }

        Label {
            text: "Deletes ~/.config/niri/config.d/15-outputs.kdl and reloads niri. "
                + "Saved profiles are kept."
            color: root.theme.subtext
            wrapMode: Text.WordWrap
            width: 380
        }
    }
}

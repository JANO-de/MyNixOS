// Emoji / symbol picker. Type to search (e.g. "heart"); click to copy, Shift+click keeps the panel open.
import QtQuick
import qs.config
import qs.services
import qs.components

PanelFrame {
    id: p
    title: "Emoji"; icon: "mood"
    readonly property var results: Emoji.search(search.text)

    Component.onCompleted: { UiState.panelKeys = true; focusTimer.start() }
    Component.onDestruction: UiState.panelKeys = false
    Timer { id: focusTimer; interval: 120; onTriggered: search.forceActive() }

    Field {
        id: search
        function forceActive() { forceActiveFocus(); }
        anchors { top: parent.top; left: parent.left; right: parent.right }
        implicitWidth: parent.width; placeholder: "Search emoji…"
    }
    GridView {
        anchors { top: search.bottom; topMargin: 8; left: parent.left; right: parent.right; bottom: parent.bottom }
        clip: true; boundsBehavior: Flickable.StopAtBounds
        cellWidth: 44; cellHeight: 44
        model: p.results
        delegate: Rectangle {
            required property string modelData
            width: 40; height: 40; radius: 12
            color: ma.containsMouse ? "#33ffffff" : "transparent"
            Text { anchors.centerIn: parent; text: Emoji.glyph(modelData); font.pixelSize: 24 }
            MouseArea {
                id: ma; anchors.fill: parent; hoverEnabled: true
                onClicked: m => { Emoji.copy(Emoji.glyph(modelData)); if (Config.system.emojiClose && !(m.modifiers & Qt.ShiftModifier)) UiState.closePanel() }
            }
        }
        Text { visible: p.results.length === 0; text: "No emoji found"; color: "#77ffffff"; font.pixelSize: 13 }
    }
}

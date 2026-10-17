// Quick note: type and it autosaves to Config.system.noteFile (Markdown).
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.components

PanelFrame {
    id: p
    title: "Quick note"; icon: "edit_note"
    FileView { id: file; path: Config.system.noteFile; blockLoading: true }
    function save() { file.setText(area.text) }
    Component.onCompleted: {
        UiState.panelKeys = true;
        Quickshell.execDetached(["mkdir", "-p", Config.system.noteFile.replace(/\/[^\/]*$/, "")]);
        try { area.text = file.text() } catch (e) { area.text = "" }
        focusTimer.start()
    }
    Component.onDestruction: { UiState.panelKeys = false; p.save() }
    Timer { id: focusTimer; interval: 120; onTriggered: area.forceActiveFocus() }
    Timer { id: saveTimer; interval: 700; onTriggered: p.save() }

    PillButton { parent: p; z: 5; label: "Open"; icon: "folder_open"; implicitHeight: 30
        anchors { top: parent.top; right: parent.right; topMargin: 15; rightMargin: 56 }
        onClicked: { p.save(); Quickshell.execDetached(["xdg-open", Config.system.noteFile]) } }
    Rectangle {
        anchors.fill: parent; radius: 16; color: "#14ffffff"
        Flickable {
            id: fl; anchors { fill: parent; margins: 12 } clip: true
            contentHeight: area.implicitHeight; boundsBehavior: Flickable.StopAtBounds
            TextEdit {
                id: area; width: fl.width; wrapMode: TextEdit.Wrap; selectByMouse: true
                color: "white"; font.pixelSize: 14; selectionColor: Theme.primary
                onTextChanged: saveTimer.restart()
                Text { visible: !area.text && !area.activeFocus; text: "Write something…"; color: "#66ffffff"; font.pixelSize: 14 }
            }
        }
    }
}

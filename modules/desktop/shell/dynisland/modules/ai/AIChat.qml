// =============================================================================
//  AIChat — centered chat panel for services/AI.qml (Anthropic API).
//  open: IPC `ai toggle` (bind a key in niri), UiState.aiOpen
// =============================================================================
import QtQuick
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

        Rectangle { anchors.fill: parent; color: "#66000000" }
        MouseArea { anchors.fill: parent; onClicked: win.close() }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.5, 620); height: Math.min(parent.height * 0.75, 680)
            radius: 22; color: Theme.surfaceContainer; border.width: 1; border.color: "#33ffffff"
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 1.0; shadowColor: "#90000000"; shadowVerticalOffset: 8 }
            MouseArea { anchors.fill: parent }   // swallow clicks so they don't close

            Column {
                anchors { fill: parent; margins: 16 }
                spacing: 10

                Row {
                    width: parent.width
                    Text { text: "Claude"; color: "white"; font.pixelSize: 16; font.bold: true }
                    Item { width: parent.width - 140; height: 1 }
                    IconButton { diameter: 28; iconSize: 16; icon: "delete"; onClicked: AI.clear(); tip: "Clear chat" }
                    IconButton { diameter: 28; iconSize: 16; icon: "close"; onClicked: win.close() }
                }

                Rectangle {
                    width: parent.width; height: parent.height - 108
                    radius: 14; color: Theme.surfaceContainerHigh
                    ListView {
                        id: list
                        anchors { fill: parent; margins: 10 }
                        clip: true; spacing: 10
                        model: AI.messages
                        onCountChanged: positionViewAtEnd()
                        delegate: Column {
                            required property var modelData
                            width: list.width
                            readonly property bool me: modelData.role === "user"
                            Text { text: me ? "You" : "Claude"; color: "#99ffffff"; font.pixelSize: 11 }
                            Text { width: list.width; text: modelData.text; color: "white"; font.pixelSize: 14; wrapMode: Text.Wrap }
                        }
                        footer: Item {
                            width: list.width; height: AI.busy ? 24 : 0
                            Text { visible: AI.busy; text: "Thinking…"; color: "#88ffffff"; font.pixelSize: 13 }
                        }
                    }
                }

                Text { visible: AI.error !== ""; text: AI.error; color: "#e06060"; font.pixelSize: 12; width: parent.width; wrapMode: Text.Wrap }

                Rectangle {
                    width: parent.width; height: 44; radius: 22
                    color: Theme.surfaceContainerHigh; border.width: 1; border.color: input.activeFocus ? Theme.primary : "#22ffffff"
                    TextInput {
                        id: input
                        anchors { fill: parent; leftMargin: 16; rightMargin: 44 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: "white"; font.pixelSize: 14; clip: true
                        Component.onCompleted: forceActiveFocus()
                        onAccepted: { AI.send(text); text = "" }
                        Keys.onPressed: e => { if (e.key === Qt.Key_Escape) win.close() }
                        Text { visible: input.text === ""; anchors.verticalCenter: parent.verticalCenter
                               text: Config.ai.apiKey ? "Ask Claude…" : "Set an API key in Settings > AI"; color: "#77ffffff"; font.pixelSize: 14 }
                    }
                    IconButton { anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                                 diameter: 34; iconSize: 16; icon: "send"; active: true
                                 onClicked: { AI.send(input.text); input.text = "" } }
                }
            }
        }
    }
}

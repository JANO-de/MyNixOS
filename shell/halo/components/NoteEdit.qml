import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

// Note editor: a card in an Overlay window (the Background Desktop window cannot take keyboard focus).
// Saves into the widget's cfg.text when closed (Done, back gesture, or UI.closeNote()).
PanelWindow {
    id: root

    readonly property bool shown: UI.noteId !== ""
    property string curId: ""

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Math.round(screen.height * 0.44)
    color: "transparent"
    visible: shown
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-note"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        anchors.margins: 14
        radius: 32
        color: Theme.surfaceHigh
        border.color: Theme.glassStroke
        border.width: 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 26
            anchors.top: parent.top
            anchors.topMargin: 22
            text: "Note"
            color: Theme.dim
            font.pixelSize: 16
        }
        Rectangle {
            id: done
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 12
            width: 84
            height: 44
            radius: 22
            color: Theme.accent
            Text {
                anchors.centerIn: parent
                text: "Done"
                color: Theme.accentInk
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            MouseArea { anchors.fill: parent; onClicked: UI.closeNote() }
        }

        Flickable {
            id: fl
            anchors.fill: parent
            anchors.topMargin: 66
            anchors.leftMargin: 26
            anchors.rightMargin: 26
            anchors.bottomMargin: 20
            clip: true
            contentWidth: width
            contentHeight: Math.max(height, edit.implicitHeight)
            boundsBehavior: Flickable.StopAtBounds

            TextEdit {
                id: edit
                width: fl.width
                height: Math.max(fl.height, implicitHeight)
                color: Theme.text
                font.pixelSize: 19
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                onActiveFocusChanged: {
                    if (activeFocus && Mode.tablet)
                        Kbd.show();
                }
                onCursorRectangleChanged: {
                    const r = cursorRectangle;
                    if (r.y < fl.contentY)
                        fl.contentY = r.y;
                    else if (r.y + r.height > fl.contentY + fl.height)
                        fl.contentY = r.y + r.height - fl.height;
                }
            }
            // Every touch raises the keyboard again (also after it was dismissed with the X).
            PointHandler {
                onActiveChanged: {
                    if (!active)
                        return;
                    edit.forceActiveFocus();
                    if (Mode.tablet)
                        Kbd.show();
                }
            }
        }
    }

    Connections {
        target: UI
        function onNoteIdChanged() {
            if (UI.noteId !== "") {
                root.curId = UI.noteId;
                const w = Home.winstById(root.curId);
                edit.text = w && w.cfg && w.cfg.text ? w.cfg.text : "";
                edit.forceActiveFocus();
                edit.cursorPosition = edit.length;
            } else if (root.curId !== "") {
                Home.setCfg(root.curId, { text: edit.text });
                root.curId = "";
                Kbd.hideQuiet();
            }
        }
    }
}

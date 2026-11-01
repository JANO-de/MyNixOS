import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

// Search bar for the App Library: a thin Overlay window along the top that takes keyboard focus
// (the home/Desktop window sits on the Background layer and cannot).
PanelWindow {
    id: root

    readonly property bool shown: UI.libSearchOpen

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 96
    color: "transparent"
    visible: shown
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-libsearch"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        anchors.margins: 14
        radius: 32
        color: Theme.surfaceHigh
        border.color: Theme.glassStroke
        border.width: 1

        SetInput {
            id: field
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: done.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            placeholder: "Search apps"
            grab: root.shown
            onTextChanged: if (UI.libQuery !== text) UI.libQuery = text
            onAccepted: root.close()
        }
        Rectangle {
            id: done
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
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
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }
    }

    function close() {
        UI.libSearchOpen = false;
        Kbd.hideQuiet();
    }

    // The pill's clear button / opening the bar keeps the field in sync with the stored query.
    Connections {
        target: UI
        function onLibQueryChanged() { if (field.text !== UI.libQuery) field.text = UI.libQuery; }
        function onLibSearchOpenChanged() { if (UI.libSearchOpen) field.text = UI.libQuery; }
    }
}

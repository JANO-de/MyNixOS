// =============================================================================
//  DockIcon — one app. Size follows a gaussian of the mouse distance
//  (macOS-style magnification). `mouseX` is relative to the dock window center;
//  `slot` is this icon's nominal (unmagnified) offset from that center.
//    left click  : launch, or focus the first window if running
//    middle click: launch a new instance
//    right click : pin / unpin
// =============================================================================
import QtQuick
import Quickshell
import qs.config
import qs.services

Item {
    id: ic
    required property var item          // {key, appId, entry, pinned}
    required property real mouseX       // -10000 when the mouse is away
    required property real slot
    signal pinToggled(string appId)

    readonly property real base: Config.dock.iconSize
    readonly property real sigma: base * 1.6
    readonly property real mag: 1 + (Config.dock.magnification - 1)
                                 * Math.exp(-Math.pow(mouseX - slot, 2) / (2 * sigma * sigma))
    readonly property var wins: Niri.windowsFor(item.appId)
    readonly property bool running: wins.length > 0

    width: base * mag; height: base * mag
    Behavior on width { enabled: ic.mouseX < -5000; NumberAnimation { duration: 140 } }   // smooth only when leaving

    Image {
        id: img
        anchors.fill: parent
        source: Quickshell.iconPath(ic.item.entry ? ic.item.entry.icon : ic.item.appId, "application-x-executable")
        sourceSize: Qt.size(128, 128); smooth: true; mipmap: true
        transform: Translate { id: bounce }
    }

    // running indicator
    Rectangle {
        visible: ic.running; width: 5; height: 5; radius: 2.5; color: Theme.onSurface
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 3 }
    }

    // name tooltip
    Rectangle {
        visible: ma.containsMouse; opacity: visible ? 1 : 0
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.top; bottomMargin: 10 }
        width: tip.implicitWidth + 20; height: 26; radius: 8; color: Theme.surfaceContainerHigh
        Text { id: tip; anchors.centerIn: parent; color: Theme.onSurface; font.pixelSize: 12
               text: ic.item.entry ? ic.item.entry.name : ic.item.appId }
    }

    SequentialAnimation {   // launch bounce
        id: bounceAnim
        NumberAnimation { target: bounce; property: "y"; to: -ic.base * 0.4; duration: 180; easing.type: Easing.OutQuad }
        NumberAnimation { target: bounce; property: "y"; to: 0; duration: 220; easing.type: Easing.OutBounce }
    }

    MouseArea {
        id: ma
        anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) { ic.pinToggled(ic.item.appId); return }
            if (mouse.button === Qt.LeftButton && ic.running) { Niri.focus(ic.wins[0].id); return }
            if (ic.item.entry) { ic.item.entry.execute(); bounceAnim.start() }
        }
    }
}

// One app in the grid: icon + name. Hover = select, click = launch, right-click = menu.
import QtQuick
import qs.services

Item {
    id: c
    property var app                      // { entry, id, name, cat, ... } from Launcher.apps
    property bool current: false          // selected by keyboard/hover
    signal hovered()
    signal activated()
    signal menuRequested(real x, real y)  // click position in window coordinates

    Rectangle {
        anchors { fill: parent; margins: 6 }
        radius: 18
        color: c.current ? "#26ffffff" : "transparent"
        Behavior on color { ColorAnimation { duration: 90 } }
    }
    Column {
        anchors.centerIn: parent; spacing: 8
        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 68; height: 68
            source: Launcher.iconFor(c.app ? c.app.entry : null)
            sourceSize: Qt.size(128, 128); smooth: true; mipmap: true
            scale: c.current ? 1.08 : 1
            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        }
        Text {
            width: c.width - 20; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
            text: c.app ? c.app.name : ""
            color: "white"; font.pixelSize: 13
        }
    }
    MouseArea {
        anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPositionChanged: c.hovered()           // only when the mouse really moves (typing keeps selection)
        onClicked: m => {
            if (m.button === Qt.RightButton) { const p = c.mapToItem(null, m.x, m.y); c.menuRequested(p.x, p.y) }   // window coordinates
            else c.activated()
        }
    }
}

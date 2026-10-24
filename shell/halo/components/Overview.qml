import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// App overview (recents): live window cards. Swipe a card up to close it, tap to open it,
// "Close all" at the bottom. Fades/scales in under the finger during the bottom-edge swipe.
PanelWindow {
    id: root

    property real progress: UI.overviewDragging ? UI.overviewDrag : (UI.overviewOpen ? 1 : 0)
    Behavior on progress {
        enabled: !UI.overviewDragging
        NumberAnimation { duration: 340; easing.type: Easing.OutQuint }
    }

    // Dims and shrinks while the finger is past the half-way mark (release = home).
    property real hint: UI.overviewDragging && UI.overviewHomeHint ? 1 : 0
    Behavior on hint { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    readonly property int count: ToplevelManager.toplevels.values.length

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    visible: progress > 0.001 || UI.overviewOpen || UI.overviewDragging
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-overview"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Timer {
        id: homeAfterClear
        interval: 280
        onTriggered: UI.goHome()
    }

    function closeAll() {
        const all = ToplevelManager.toplevels.values.slice();
        for (const t of all)
            t.close();
        homeAfterClear.restart();
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.04, 0.04, 0.07, 0.62)
        opacity: root.progress

        // Empty space: tap = back to the current app, swipe up = home screen.
        MouseArea {
            anchors.fill: parent
            property real startY: 0
            onPressed: mouse => startY = mouse.y
            onReleased: mouse => {
                if (startY - mouse.y > 120)
                    UI.goHome();
                else if (Math.abs(startY - mouse.y) < 12)
                    UI.closeOverview();
            }
        }
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: Math.min(1, root.progress * 1.5) * (1 - 0.65 * root.hint)
        scale: (0.86 + 0.14 * root.progress) * (1 - 0.1 * root.hint)
        transformOrigin: Item.Center

        readonly property real aspect: root.screen ? root.screen.width / root.screen.height : 1.6
        readonly property real cardH: Math.min(height * 0.6, width * 0.72 / aspect)
        readonly property real cardW: cardH * aspect
        readonly property real headerH: 44

        Text {
            visible: root.count === 0
            anchors.centerIn: parent
            text: "No open apps"
            color: Theme.dim
            font.pixelSize: 20
        }

        ListView {
            id: list
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -40
            height: stage.cardH + stage.headerH
            orientation: ListView.Horizontal
            spacing: 32
            leftMargin: Math.max(24, (width - stage.cardW) / 2)
            rightMargin: leftMargin
            snapMode: ListView.SnapToItem
            boundsBehavior: Flickable.DragAndOvershootBounds
            model: ToplevelManager.toplevels

            displaced: Transition {
                NumberAnimation { properties: "x"; duration: 260; easing.type: Easing.OutCubic }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 160 }
            }

            delegate: Item {
                id: cell

                required property var modelData
                readonly property var entry: modelData.appId ? DesktopEntries.heuristicLookup(modelData.appId) : null

                width: stage.cardW
                height: list.height

                // App icon + title
                Row {
                    x: 6
                    anchors.top: parent.top
                    spacing: 10
                    opacity: card.opacity

                    Image {
                        width: 30
                        height: 30
                        source: cell.entry ? Apps.iconSource(cell.entry.icon) : ""
                        sourceSize: Qt.size(60, 60)
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: stage.cardW - 60
                        elide: Text.ElideRight
                        text: cell.modelData.title !== "" ? cell.modelData.title : cell.modelData.appId
                        color: Theme.text
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    id: card
                    width: parent.width
                    height: stage.cardH
                    y: stage.headerH
                    radius: 18
                    color: Qt.rgba(0.1, 0.1, 0.12, 1)
                    border.color: Theme.glassStroke
                    border.width: 1
                    opacity: 1 - Math.max(0, Math.min(1, (stage.headerH - y) / (stage.cardH * 0.8)))
                    scale: ma.pressed && !ma.drag.active ? 0.97 : 1

                    Behavior on y { enabled: !ma.drag.active && !closeAnim.running; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: cell.modelData.title
                        color: Theme.dim
                        font.pixelSize: 16
                        visible: !view.hasContent
                    }

                    ScreencopyView {
                        id: view
                        anchors.fill: parent
                        anchors.margins: 2
                        captureSource: cell.modelData
                        live: root.progress > 0.01
                    }

                    NumberAnimation {
                        id: closeAnim
                        target: card
                        property: "y"
                        to: -stage.cardH - 120
                        duration: 220
                        easing.type: Easing.OutCubic
                        onFinished: cell.modelData.close()
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        drag.target: card
                        drag.axis: Drag.YAxis
                        drag.minimumY: -stage.cardH - 200
                        drag.maximumY: stage.headerH

                        property real lastY: 0
                        property real lastT: 0
                        property real vy: 0 // px/ms, - is up

                        onPressed: {
                            lastY = card.y;
                            lastT = Date.now();
                            vy = 0;
                        }
                        onPositionChanged: {
                            if (!drag.active)
                                return;
                            const now = Date.now();
                            const dt = now - lastT;
                            if (dt > 0)
                                vy = 0.7 * vy + 0.3 * ((card.y - lastY) / dt);
                            lastY = card.y;
                            lastT = now;
                        }
                        onReleased: {
                            if (!drag.active)
                                return;
                            if (card.y < stage.headerH - stage.cardH * 0.22 || vy < -0.6)
                                closeAnim.start();
                            else
                                card.y = stage.headerH;
                        }
                        onClicked: {
                            UI.closeOverview();
                            cell.modelData.activate();
                        }
                    }
                }
            }
        }

        // Close all
        Rectangle {
            visible: root.count > 0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 150
            width: closeText.implicitWidth + 56
            height: 48
            radius: 24
            color: closeAllArea.pressed ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.16)
            border.color: Theme.glassStroke
            border.width: 1
            Behavior on color { ColorAnimation { duration: 90 } }

            Text {
                id: closeText
                anchors.centerIn: parent
                text: "Close all"
                color: Theme.text
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: closeAllArea
                anchors.fill: parent
                onClicked: root.closeAll()
            }
        }
    }
}

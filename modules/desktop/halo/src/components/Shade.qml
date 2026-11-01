import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// iPad-style control center with Android-style pull: the first pull shows the control
// center, dragging the grabber further expands it into the notification list,
// dragging it up closes it. Long-press a tile to customize.
PanelWindow {
    id: root

    readonly property bool shown: UI.shadeOpen
    property bool editing: false

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    // 0 = hidden, 1 = open. Follows the finger while pulled from the top edge (TopEdge.qml).
    property real progress: UI.shadeDragging ? UI.shadeDrag : (UI.shadeOpen ? 1 : 0)
    Behavior on progress {
        enabled: !UI.shadeDragging
        NumberAnimation { duration: 380; easing.type: Easing.OutQuint }
    }

    visible: progress > 0.001 || shown || UI.shadeDragging
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-shade"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    onShownChanged: {
        if (shown) {
            panel.expand = 0;
            editing = false;
            System.refresh();
            Controls.refresh();
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.shown
        onTriggered: System.refresh()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Backdrop: fades with the panel, tap closes.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.38)
        opacity: root.progress

        MouseArea {
            anchors.fill: parent
            onClicked: UI.tapCloseShade()
        }
    }

    Rectangle {
        id: panel

        property real expand: 0 // 0 = control center, 1 = + notifications
        property bool dragging: false
        readonly property real collapsedH: content.implicitHeight + 40 + grabberZone.height
        readonly property real maxH: root.height - 24

        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 24, 600)
        height: collapsedH + expand * Math.max(0, maxH - collapsedH)
        radius: 34
        color: Qt.rgba(0.13, 0.13, 0.16, 0.74)
        border.color: Theme.glassStroke
        border.width: 1
        opacity: Math.min(1, root.progress * 3)
        y: 12 - (1 - root.progress) * (height + 36)

        Behavior on expand { enabled: !panel.dragging; NumberAnimation { duration: 340; easing.type: Easing.OutQuint } }

        // Swallow taps on the panel.
        MouseArea { anchors.fill: parent }

        Column {
            id: content
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 14

            Item {
                width: parent.width
                height: 36

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.text
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: Qt.rgba(1, 1, 1, 0.14)

                        QIcon {
                            anchors.centerIn: parent
                            size: 20
                            name: "gear"
                            color: Theme.text
                        }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: UI.openSettings()
                        }
                    }

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: root.editing ? Theme.accent : Qt.rgba(1, 1, 1, 0.14)
                        Behavior on color { ColorAnimation { duration: 140 } }

                        QIcon {
                            anchors.centerIn: parent
                            size: 20
                            name: root.editing ? "check" : "edit"
                            color: root.editing ? Theme.accentInk : Theme.text
                        }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: root.editing = !root.editing
                        }
                    }
                }
            }

            ControlGrid {
                width: parent.width
                editing: root.editing
                onCloseRequested: UI.closeShade()
                onEditRequested: root.editing = true
            }

            // Edit mode: tiles that can be added back.
            Flow {
                visible: root.editing && Controls.available.length > 0
                width: parent.width
                spacing: 8

                Repeater {
                    model: Controls.available

                    Rectangle {
                        required property string modelData
                        width: chip.implicitWidth + 52
                        height: 36
                        radius: 18
                        color: Qt.rgba(1, 1, 1, 0.14)

                        Text {
                            id: chip
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 38
                            text: Controls.info(parent.modelData).title
                            color: Theme.text
                            font.pixelSize: 13
                        }
                        QIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            size: 18
                            name: "plus"
                            color: Theme.text
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Controls.add(parent.modelData)
                        }
                    }
                }
            }

            QsSlider {
                width: parent.width
                icon: "sun"
                label: "Brightness"
                value: System.brightness
                onMoved: v => System.setBrightness(v)
            }

            QsSlider {
                width: parent.width
                icon: System.muted ? "mute" : "volume"
                label: System.muted ? "Volume (muted)" : "Volume"
                value: System.muted ? 0 : System.volume
                onMoved: v => System.setVolume(v)
            }
        }

        // Notifications: revealed as the panel is pulled further down.
        Item {
            id: notifArea
            anchors.top: content.bottom
            anchors.topMargin: 14
            anchors.bottom: grabberZone.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            opacity: Math.max(0, (panel.expand - 0.25) / 0.75)
            visible: opacity > 0.01
            clip: true

            Item {
                id: notifHeader
                width: parent.width
                height: 30

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications"
                    color: Theme.text
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }
                Text {
                    visible: Notifs.count > 0
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clear all"
                    color: Theme.accent
                    font.pixelSize: 14
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            Text {
                visible: Notifs.count === 0
                anchors.centerIn: parent
                text: "No notifications"
                color: Theme.dim
                font.pixelSize: 15
            }

            ListView {
                anchors.top: notifHeader.bottom
                anchors.topMargin: 8
                anchors.bottom: parent.bottom
                width: parent.width
                spacing: 8
                clip: true
                model: Notifs.list
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: row
                    required property var modelData

                    width: ListView.view.width
                    height: card.height

                    Rectangle {
                        id: card
                        width: parent.width
                        height: body.implicitHeight + 24
                        radius: 20
                        color: Qt.rgba(1, 1, 1, 0.12)
                        opacity: 1 - Math.min(1, Math.abs(x) / width)
                        Behavior on x { enabled: !swipe.pressed; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        Column {
                            id: body
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 16
                            spacing: 2

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: row.modelData.appName
                                color: Theme.dim
                                font.pixelSize: 12
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: row.modelData.summary
                                color: Theme.text
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                            Text {
                                width: parent.width
                                visible: text !== ""
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                text: row.modelData.body
                                color: Theme.text
                                opacity: 0.85
                                font.pixelSize: 13
                            }
                        }

                        // Swipe sideways to dismiss.
                        MouseArea {
                            id: swipe
                            anchors.fill: parent
                            drag.target: card
                            drag.axis: Drag.XAxis
                            onReleased: {
                                if (Math.abs(card.x) > card.width * 0.3)
                                    row.modelData.dismiss();
                                else
                                    card.x = 0;
                            }
                        }
                    }
                }
            }
        }

        // Grabber: drag down = more notifications, drag up = close.
        Item {
            id: grabberZone
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40

            Rectangle {
                anchors.centerIn: parent
                width: 44
                height: 5
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.45)
            }

            MouseArea {
                id: grab
                anchors.fill: parent
                preventStealing: true

                property real startY: 0
                property real startExpand: 0
                property real lastY: 0
                property real lastT: 0
                property real vel: 0 // px/ms, + is down

                function gy(mouse) {
                    return mapToItem(null, mouse.x, mouse.y).y;
                }

                onPressed: mouse => {
                    startY = gy(mouse);
                    lastY = startY;
                    lastT = Date.now();
                    vel = 0;
                    startExpand = panel.expand;
                    panel.dragging = true;
                    UI.shadeDrag = 1;
                    UI.shadeDragging = true;
                }
                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    const y = gy(mouse);
                    const range = Math.max(1, panel.maxH - panel.collapsedH);
                    const p = startExpand + (y - startY) / range;
                    if (p < 0) {
                        // Dragging up: the panel follows the finger out of the screen.
                        panel.expand = 0;
                        UI.shadeDrag = Math.max(0, 1 + (p * range) / (panel.height + 36));
                    } else {
                        panel.expand = Math.min(1, p);
                        UI.shadeDrag = 1;
                    }
                    const now = Date.now();
                    const dt = now - lastT;
                    if (dt > 0)
                        vel = 0.7 * vel + 0.3 * ((y - lastY) / dt);
                    lastY = y;
                    lastT = now;
                }
                onReleased: {
                    panel.dragging = false;
                    const closing = UI.shadeDrag < 0.8 || (UI.shadeDrag < 0.97 && vel < -0.4);
                    if (closing)
                        UI.shadeOpen = false;
                    else
                        panel.expand = (panel.expand > 0.5 && vel > -0.4) || vel > 0.5 ? 1 : 0;
                    UI.shadeDragging = false;
                }
                onCanceled: {
                    panel.dragging = false;
                    UI.shadeDragging = false;
                }
            }
        }
    }
}

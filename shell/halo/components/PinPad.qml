import QtQuick
import qs.services

// Passcode entry: dots + 3x4 keypad. Calls submit(pin) when the PIN length is reached.
Item {
    id: root

    property int length: 6
    property string entry: ""
    signal submit(string pin)
    signal cancel
    signal usePassword

    implicitWidth: 330
    implicitHeight: col.implicitHeight

    function press(d) {
        if (Lock.cooling || entry.length >= length)
            return;
        entry += d;
        if (entry.length === length)
            sendTimer.start();
    }

    function back() {
        entry = entry.slice(0, -1);
    }

    Timer {
        id: sendTimer
        interval: 90
        onTriggered: {
            root.submit(root.entry);
            root.entry = "";
        }
    }

    Connections {
        target: Lock
        function onWrong() {
            shake.restart();
        }
    }

    Column {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 26

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Lock.cooling ? "Try again in " + Lock.cooldownSecs + " s" : (Lock.error !== "" ? Lock.error : "Enter passcode")
            color: Theme.text
            font.pixelSize: 20
            font.weight: Font.Medium
        }

        Row {
            id: dots
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 18

            SequentialAnimation {
                id: shake
                NumberAnimation { target: dots; property: "x"; to: dots.x + 16; duration: 50 }
                NumberAnimation { target: dots; property: "x"; to: dots.x - 16; duration: 80 }
                NumberAnimation { target: dots; property: "x"; to: dots.x + 10; duration: 70 }
                NumberAnimation { target: dots; property: "x"; to: dots.x; duration: 60 }
            }

            Repeater {
                model: root.length
                Rectangle {
                    required property int index
                    width: 16
                    height: 16
                    radius: 8
                    color: index < root.entry.length ? Theme.text : "transparent"
                    border.color: Theme.text
                    border.width: 2
                    Behavior on color { ColorAnimation { duration: 80 } }
                }
            }
        }

        Grid {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 3
            spacing: 20

            Repeater {
                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"]

                Item {
                    required property string modelData
                    width: 84
                    height: 84
                    opacity: Lock.cooling ? 0.4 : 1

                    Rectangle {
                        anchors.fill: parent
                        radius: 42
                        visible: parent.modelData !== ""
                        color: key.pressed ? Qt.rgba(1, 1, 1, 0.34) : Qt.rgba(1, 1, 1, parent.modelData === "⌫" ? 0.0 : 0.16)
                        scale: key.pressed ? 0.94 : 1
                        Behavior on color { ColorAnimation { duration: 70 } }
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text: parent.parent.modelData
                            color: Theme.text
                            font.pixelSize: parent.parent.modelData === "⌫" ? 28 : 36
                            font.weight: Font.Light
                        }
                    }
                    MouseArea {
                        id: key
                        anchors.fill: parent
                        enabled: parent.modelData !== ""
                        onClicked: parent.modelData === "⌫" ? root.back() : root.press(parent.modelData)
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 60

            Text {
                text: "Cancel"
                color: Theme.text
                font.pixelSize: 17
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -14
                    onClicked: root.cancel()
                }
            }
            Text {
                text: "Use password"
                color: Theme.text
                font.pixelSize: 17
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -14
                    onClicked: root.usePassword()
                }
            }
        }
    }
}

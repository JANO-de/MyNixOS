import QtQuick

// Minimal on-screen keyboard for the lock screen (wvkbd cannot draw above the session lock).
// Types into `target` (a TextInput). Layers: letters (shift) and numbers/symbols.
Item {
    id: root

    property Item target: null
    property bool shift: false
    property bool symbols: false
    signal enter

    readonly property var letterRows: [["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"], ["a", "s", "d", "f", "g", "h", "j", "k", "l"], ["z", "x", "c", "v", "b", "n", "m"]]
    readonly property var symbolRows: [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], ["-", "/", ":", ";", "(", ")", "&", "@", "\""], [".", ",", "?", "!", "'", "#", "%"]]
    readonly property var rows: symbols ? symbolRows : letterRows
    readonly property real keyH: 60
    readonly property real gap: 8
    readonly property real keyW: (width - gap * 9) / 10

    implicitHeight: keyH * 4 + gap * 3

    function type(ch) {
        if (!target)
            return;
        target.insert(target.cursorPosition, shift && !symbols ? ch.toUpperCase() : ch);
        if (shift)
            shift = false;
    }

    function backspace() {
        if (target && target.cursorPosition > 0)
            target.remove(target.cursorPosition - 1, target.cursorPosition);
    }

    component Key: Rectangle {
        id: k
        property string label: ""
        property bool accent: false
        signal tapped
        radius: 12
        color: kArea.pressed ? Qt.rgba(1, 1, 1, 0.38) : (accent ? Qt.rgba(1, 1, 1, 0.26) : Qt.rgba(1, 1, 1, 0.16))
        Behavior on color { ColorAnimation { duration: 60 } }
        Text {
            anchors.centerIn: parent
            text: k.label
            color: "white"
            font.pixelSize: 22
        }
        MouseArea {
            id: kArea
            anchors.fill: parent
            onClicked: k.tapped()
        }
    }

    Column {
        anchors.fill: parent
        spacing: root.gap

        // rows 1-2
        Repeater {
            model: 2
            Row {
                required property int index
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.gap
                Repeater {
                    model: root.rows[parent.index]
                    Key {
                        required property string modelData
                        width: root.keyW
                        height: root.keyH
                        label: root.shift && !root.symbols ? modelData.toUpperCase() : modelData
                        onTapped: root.type(modelData)
                    }
                }
            }
        }

        // row 3: shift, keys, backspace
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.gap
            Key {
                width: root.keyW * 1.5
                height: root.keyH
                label: root.symbols ? "" : "⇧"
                accent: root.shift
                onTapped: if (!root.symbols) root.shift = !root.shift
            }
            Repeater {
                model: root.rows[2]
                Key {
                    required property string modelData
                    width: root.keyW
                    height: root.keyH
                    label: root.shift && !root.symbols ? modelData.toUpperCase() : modelData
                    onTapped: root.type(modelData)
                }
            }
            Key {
                width: root.keyW * 1.5
                height: root.keyH
                label: "⌫"
                onTapped: root.backspace()
            }
        }

        // row 4: layer, space, enter
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.gap
            Key {
                width: root.keyW * 2
                height: root.keyH
                label: root.symbols ? "ABC" : "123"
                onTapped: root.symbols = !root.symbols
            }
            Key {
                width: root.keyW * 5 + root.gap * 4
                height: root.keyH
                label: "space"
                onTapped: root.type(" ")
            }
            Key {
                width: root.keyW * 2
                height: root.keyH
                label: "log in"
                accent: true
                onTapped: root.enter()
            }
        }
    }
}

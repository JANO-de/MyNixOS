import QtQuick
import qs.services

// Settings text field with proper on-screen-keyboard behaviour (tablet mode):
// tap = focus + keyboard up; tap anywhere else (HaloSettings) = keyboard away; scrolls itself above the keyboard.
Rectangle {
    id: root

    property alias text: field.text
    property string placeholder: ""
    property bool password: false
    property bool grab: false // take focus (and so raise the keyboard) as soon as this turns true
    signal accepted

    // Scroll the enclosing Flickable so the field sits above the keyboard.
    function reveal() {
        let f = root.parent;
        while (f && f.contentY === undefined)
            f = f.parent;
        if (!f)
            return;
        const y = root.mapToItem(f.contentItem, 0, 0).y;
        const max = Math.max(0, f.contentHeight - f.height);
        if (y + height + 24 > f.contentY + f.height)
            f.contentY = Math.min(max, y + height + 24 - f.height);
        else if (y - 24 < f.contentY)
            f.contentY = Math.max(0, y - 24);
    }

    height: 48
    radius: 24
    color: Theme.tint(0.12)
    border.width: field.activeFocus ? 2 : 0
    border.color: Theme.accent

    // The keyboard and the shrunk window arrive a moment after the focus change.
    Timer {
        id: later
        interval: 250
        onTriggered: root.reveal()
    }
    Connections {
        target: Kbd
        function onVisibleChanged() { if (field.activeFocus) later.restart(); }
        function onMeasuredHeightChanged() { if (field.activeFocus) later.restart(); }
    }

    TextInput {
        id: field
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        verticalAlignment: TextInput.AlignVCenter
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        inputMethodHints: root.password ? (Qt.ImhSensitiveData | Qt.ImhNoPredictiveText) : Qt.ImhNone
        color: Theme.text
        font.pixelSize: 18
        clip: true
        focus: root.grab
        onAccepted: root.accepted()
        onActiveFocusChanged: {
            if (!activeFocus)
                return;
            UI.inputFocusAt = Date.now();
            if (Mode.tablet)
                Kbd.show();
            later.restart();
        }

        Text {
            visible: field.text === ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: Theme.dim
            font.pixelSize: 18
        }
    }

    // Passive: the TextInput still handles the touch itself. Every press raises the keyboard again,
    // also after it was dismissed with the X while the field kept its focus.
    PointHandler {
        onActiveChanged: {
            if (!active)
                return;
            UI.inputTapAt = Date.now();
            field.forceActiveFocus();
            if (Mode.tablet)
                Kbd.show();
            later.restart();
        }
    }
}

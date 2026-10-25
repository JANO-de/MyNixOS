import QtQuick
import qs.services

// Settings > Security: lock now and PIN status. The PIN itself is set with `halo-set-pin` in a terminal.
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    SetGroup {
        SetRow {
            glyph: "⚑"
            title: "Lock now"
            subtitle: "Same as SUPER+L"
            chevron: true
            onClicked: {
                UI.closeSettings();
                Lock.lock();
            }
        }
    }

    SetGroup {
        title: "Lock screen"
        SetRow {
            title: "PIN"
            subtitle: Lock.hasPin ? "Set (" + Lock.pinLen + " digits)" : "Not set. Run halo-set-pin in a terminal to choose one."
            tappable: false
        }
        SetRow {
            title: "Password"
            subtitle: "Your account password always works (PAM service halo)"
            tappable: false
        }
        SetRow {
            visible: Lock.failCount > 0
            title: "Wrong attempts since last unlock"
            subtitle: Lock.failCount + (Lock.cooling ? " - locked out for " + Lock.cooldownSecs + " s" : "")
            tappable: false
        }
    }

    Text {
        width: parent.width
        leftPadding: 8
        rightPadding: 8
        text: "The PIN is a convenience lock. Real protection is disk encryption plus your password."
        color: Theme.dim
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }
}

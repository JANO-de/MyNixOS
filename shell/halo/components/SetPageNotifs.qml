import QtQuick
import qs.services

// Settings > Notifications: Do Not Disturb and clearing.
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    SetGroup {
        SetRow {
            glyph: "◔"
            title: "Do Not Disturb"
            subtitle: Notifs.dnd ? "Banners are silenced; notifications still collect in the shade" : "Banners appear at the top"
            onClicked: Notifs.dnd = !Notifs.dnd

            SetSwitch {
                checked: Notifs.dnd
                onToggled: Notifs.dnd = !Notifs.dnd
            }
        }
    }

    SetGroup {
        SetRow {
            title: Notifs.count === 0 ? "No notifications" : "Clear " + Notifs.count + (Notifs.count === 1 ? " notification" : " notifications")
            subtitle: "Removes everything from the shade"
            tappable: Notifs.count > 0
            onClicked: Notifs.clearAll()
        }
    }
}

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

    SetGroup {
        title: "Notifications by app"

        Repeater {
            model: Notifs.seen

            SetRow {
                id: row

                required property string modelData

                title: modelData
                subtitle: Notifs.muted[modelData] ? "Silenced" : "Allowed"
                onClicked: Notifs.setMuted(modelData, !Notifs.muted[modelData])

                SetSwitch {
                    checked: !Notifs.muted[row.modelData]
                    onToggled: Notifs.setMuted(row.modelData, !Notifs.muted[row.modelData])
                }
            }
        }
        SetRow {
            visible: Notifs.seen.length === 0
            title: "No apps yet"
            subtitle: "Apps appear here after their first notification (Android apps too)"
            tappable: false
        }
    }
}

import QtQuick
import qs.services

// Settings > Updates: NixOS generations (read-only for now). Rollback is run from a terminal.
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: Info.refresh()

    SetGroup {
        title: "System"
        SetRow {
            title: Info.get("nixver")
            subtitle: "Running generation: " + Info.get("gen")
            tappable: false
        }
    }

    SetGroup {
        title: "Generations (newest first)"

        Repeater {
            model: Info.gens

            SetRow {
                required property var modelData

                title: modelData.name.replace("-link", "")
                subtitle: modelData.date + "  ·  " + modelData.target
                tappable: false
            }
        }
        SetRow {
            visible: Info.gens.length === 0
            title: "No generations found"
            subtitle: "This does not look like a NixOS system"
            tappable: false
        }
    }

    Text {
        width: parent.width
        leftPadding: 8
        rightPadding: 8
        text: "To go back one generation, run: sudo nixos-rebuild switch --rollback\nOne-tap rollback and Flatpak updates arrive with the Store app."
        color: Theme.dim
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }
}

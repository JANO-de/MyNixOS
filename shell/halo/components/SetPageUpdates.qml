import QtQuick
import Quickshell.Io
import qs.services

// Settings > Updates: NixOS generations (read-only for now). Rollback is run from a terminal.
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: Info.refresh()

    property bool armed: false
    property string result: ""
    Timer {
        id: armT
        interval: 4000
        onTriggered: page.armed = false
    }
    Process {
        id: rb
        command: ["pkexec", "halo-rollback"]
        onExited: code => {
            page.result = code === 0 ? "Rolled back. Reboot to use the previous generation." : "Rollback failed (code " + code + ")";
            Info.refresh();
        }
    }

    SetGroup {
        title: "System update"
        SetRow {
            title: Info.get("nixver")
            subtitle: "Running generation: " + Info.get("gen")
            tappable: false
        }
    }

    SetGroup {
        title: "Rollback"
        SetRow {
            glyph: "↺"
            title: page.armed ? "Tap again to roll back" : "Roll back to the previous generation"
            subtitle: page.result !== "" ? page.result : (rb.running ? "Working..." : "Takes effect at the next boot")
            tappable: !rb.running
            onClicked: {
                if (!page.armed) {
                    page.armed = true;
                    armT.restart();
                } else {
                    page.armed = false;
                    page.result = "";
                    rb.running = true;
                }
            }
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
}

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

Scope {
        id: root
        property string timeString
        Variants {
                model: Quickshell.screens
                delegate: Component {
                        PanelWindow {
                            required property var modelData
                            screen: modelData

                            exclusionMode: ExclusionMode.Ignore
                            aboveWindows: false
                            color: "transparent"
                            anchors {
                                top: true
                                left: true
                                bottom: true
                                right: true
                            }

                            Text {
                                id: timetxt
                                height: 200
                                x: parent.width - 377
                                y: 41
                                font.family: "GoMono"
                                font.italic: true
                                font.pointSize: 75
                                color: "#fbf1c7"
                                text: root.timeString
                            }
                        }
                }

        }
        Process {
            id: dateProc
            command: ["date", "+%H %M"]
            running: true
            stdout: SplitParser {
                onRead: data => timeString = data
            }
        }
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: dateProc.running = true
        }
}
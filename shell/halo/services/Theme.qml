pragma Singleton
import QtQuick
import Quickshell

// Static defaults. Step 5 replaces these with matugen output.
Singleton {
    readonly property color glass: Qt.rgba(0.13, 0.13, 0.16, 0.62)
    readonly property color glassStroke: Qt.rgba(1, 1, 1, 0.14)
    readonly property color text: "#ffffff"
    readonly property color dim: "#8e8e93"
    readonly property color accent: "#a6c8ff"
    readonly property int radius: 26
}

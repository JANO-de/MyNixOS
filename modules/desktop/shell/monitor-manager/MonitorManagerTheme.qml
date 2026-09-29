// Colour roles for the Monitor Manager UI.
//
// A real QML type (not an inline QtObject) so the roles stay statically typed,
// which keeps both the standalone window and the iNiR settings page honest
// about which colours they reference.
import QtQuick

QtObject {
    id: theme

    property color background: "#14161a"
    property color surface: "#1c1f25"
    property color fg: "#e7eaee"
    property color subtext: "#98a2ad"
    property color accent: "#4caf50"
    property color outline: "#333a43"
    property color error: "#ef5350"
}

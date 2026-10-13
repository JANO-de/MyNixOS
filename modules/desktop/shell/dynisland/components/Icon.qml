import QtQuick
import Quickshell
import qs.services

// Material Symbols by codepoint (Qt ignores the font's name ligatures).
// Font is loaded from $DYN_ICON_FONT (set by default.nix); falls back to fontconfig.
Text {
    property string name: ""
    property int size: 20
    FontLoader { id: fl; source: Quickshell.env("DYN_ICON_FONT") ? "file://" + Quickshell.env("DYN_ICON_FONT") : "" }
    text: IconMap.map[name] !== undefined ? IconMap.map[name] : name
    onNameChanged: if (IconMap.map[name] === undefined) IconMap.unknown(name)
    Component.onCompleted: if (IconMap.map[name] === undefined) IconMap.unknown(name)
    Connections { target: fl; function onStatusChanged() { if (fl.status !== FontLoader.Ready) console.warn("Icon: font did not load, status", fl.status, "path", Quickshell.env("DYN_ICON_FONT")) } }
    color: "white"
    font.family: fl.status === FontLoader.Ready ? fl.name : "DynIcons"
    font.pixelSize: size
    font.hintingPreference: Font.PreferNoHinting
    font.variableAxes: ({ "FILL": 1, "wght": 400, "GRAD": 0, "opsz": 24 })
    renderType: Text.QtRendering
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}

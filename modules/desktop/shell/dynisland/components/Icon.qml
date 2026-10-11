// Material Symbols glyph. Usage: Icon { name: "wifi"; size: 20 }
// Needs the "Material Symbols Rounded" font (pkgs.material-symbols).
import QtQuick

Text {
    property string name: ""
    property int size: 20
    text: name
    color: "white"
    font.family: "Material Symbols Rounded"
    font.pixelSize: size
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}

import QtQuick
import qs.services

// Basic calculator (+ - x / %, +/-, decimal).
Item {
    id: root

    property string disp: "0"
    property real acc: 0
    property string op: ""
    property bool fresh: true

    function fmt(v) {
        if (!isFinite(v))
            return "Error";
        let t = String(parseFloat(v.toPrecision(10)));
        return t.length > 12 ? v.toExponential(5) : t;
    }
    function calc(a, o, b) {
        switch (o) {
        case "+": return a + b;
        case "-": return a - b;
        case "x": return a * b;
        case "/": return b === 0 ? NaN : a / b;
        }
        return b;
    }
    function press(k) {
        if (k >= "0" && k <= "9") {
            disp = (fresh || disp === "0") ? k : (disp.length < 12 ? disp + k : disp);
            fresh = false;
        } else if (k === ".") {
            if (fresh) {
                disp = "0.";
                fresh = false;
            } else if (disp.indexOf(".") < 0) {
                disp += ".";
            }
        } else if (k === "C") {
            disp = "0";
            acc = 0;
            op = "";
            fresh = true;
        } else if (k === "+/-") {
            if (disp !== "0")
                disp = disp[0] === "-" ? disp.substring(1) : "-" + disp;
        } else if (k === "%") {
            disp = fmt(parseFloat(disp) / 100);
            fresh = true;
        } else if (k === "=") {
            if (op !== "") {
                disp = fmt(calc(acc, op, parseFloat(disp)));
                op = "";
                fresh = true;
            }
        } else {
            if (op !== "" && !fresh)
                disp = fmt(calc(acc, op, parseFloat(disp)));
            acc = parseFloat(disp);
            op = k;
            fresh = true;
        }
    }

    readonly property var keys: ["C", "+/-", "%", "/", "7", "8", "9", "x", "4", "5", "6", "-", "1", "2", "3", "+", "0", ".", "=", ""]
    readonly property real bh: (height - 34 - 3 * 5) / 4

    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        width: parent.width
        horizontalAlignment: Text.AlignRight
        text: root.disp
        color: Theme.text
        fontSizeMode: Text.Fit
        minimumPixelSize: 12
        font.pixelSize: 28
        font.weight: Font.Light
        height: 30
    }

    Grid {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        columns: 4
        spacing: 5

        Repeater {
            model: root.keys

            Item {
                required property string modelData
                readonly property bool isOp: modelData === "/" || modelData === "x" || modelData === "-" || modelData === "+" || modelData === "="
                width: (root.width - 15) / 4
                height: root.bh
                visible: modelData !== ""

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(width, height) / 2
                    color: parent.isOp ? Theme.accent : Qt.rgba(1, 1, 1, kma.pressed ? 0.28 : 0.14)
                }
                Text {
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: parent.isOp ? Theme.accentInk : Theme.text
                    font.pixelSize: Math.max(11, root.bh * 0.45)
                }
                MouseArea {
                    id: kma
                    anchors.fill: parent
                    onClicked: root.press(parent.modelData)
                }
            }
        }
    }
}

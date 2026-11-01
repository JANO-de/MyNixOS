import QtQuick
import Quickshell
import qs.common
import qs.suite

ShellRoot {
    SuiteWindow {
        id: win

        title: "Calculator"
        implicitWidth: 460
        implicitHeight: 720

        property string expr: ""
        property bool fresh: false
        readonly property string result: evalExpr(expr)

        // k = token used by press(); ico = line icon drawn instead of the text
        readonly property var keys: [
            { k: "C" }, { k: "(" }, { k: ")" }, { k: "÷", ico: "divide" },
            { k: "7" }, { k: "8" }, { k: "9" }, { k: "×", ico: "close" },
            { k: "4" }, { k: "5" }, { k: "6" }, { k: "-", ico: "minus" },
            { k: "1" }, { k: "2" }, { k: "3" }, { k: "+", ico: "plus" },
            { k: "0" }, { k: "." }, { k: "⌫", ico: "backspace" }, { k: "=", ico: "equals" }
        ]

        function evalExpr(x) {
            if (x === "")
                return "";
            let e = x.replace(/×/g, "*").replace(/÷/g, "/").replace(/(\d+(?:\.\d+)?)%/g, "($1/100)");
            if (!/^[0-9+\-*\/.() ]+$/.test(e))
                return "";
            try {
                const v = eval(e);
                if (typeof v !== "number" || !isFinite(v))
                    return "Error";
                return String(Math.round(v * 1e10) / 1e10);
            } catch (err) {
                return "";
            }
        }
        function press(k) {
            const ops = "+-×÷";
            if (k === "C") {
                expr = "";
                fresh = false;
            } else if (k === "⌫") {
                expr = expr.slice(0, -1);
            } else if (k === "=") {
                if (result !== "" && result !== "Error") {
                    expr = result;
                    fresh = true;
                }
            } else {
                const isOp = ops.indexOf(k) >= 0;
                if (fresh && !isOp && k !== "%")
                    expr = "";
                fresh = false;
                if (isOp && expr !== "" && ops.indexOf(expr.slice(-1)) >= 0)
                    expr = expr.slice(0, -1);
                expr += k;
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: 16

            Column {
                id: disp
                width: parent.width
                height: 150
                spacing: 4
                Text {
                    width: parent.width
                    height: 54
                    rightPadding: 8
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    text: win.expr === "" ? "0" : win.expr
                    color: AppTheme.dim
                    font.pixelSize: 26
                    elide: Text.ElideLeft
                }
                Text {
                    width: parent.width
                    height: 84
                    rightPadding: 8
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    text: win.result
                    color: win.result === "Error" ? AppTheme.danger : AppTheme.text
                    font.pixelSize: 56
                    font.weight: Font.Light
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 24
                    elide: Text.ElideLeft
                }
            }

            Grid {
                anchors.top: disp.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                columns: 4
                spacing: 10
                readonly property real bw: (width - 30) / 4
                readonly property real bh: (height - 40) / 5

                Repeater {
                    model: win.keys

                    Rectangle {
                        required property var modelData
                        readonly property bool op: "÷×-+=".indexOf(modelData.k) >= 0
                        readonly property bool fn: "C()⌫".indexOf(modelData.k) >= 0
                        width: parent.bw
                        height: parent.bh
                        radius: Math.min(width, height) / 2
                        color: op ? (kt.pressed ? Qt.lighter(AppTheme.accent, 1.15) : AppTheme.accent)
                                  : (kt.pressed ? AppTheme.cardHigh : (fn ? AppTheme.tint(0.12) : AppTheme.card))
                        scale: kt.pressed ? 0.94 : 1
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 90 } }
                        Ico {
                            visible: modelData.ico !== undefined
                            anchors.centerIn: parent
                            name: modelData.ico || ""
                            size: 30
                            color: parent.op ? AppTheme.accentInk : AppTheme.text
                        }
                        Text {
                            visible: modelData.ico === undefined
                            anchors.centerIn: parent
                            text: modelData.k
                            color: parent.fn ? AppTheme.accent : AppTheme.text
                            font.pixelSize: 30
                        }
                        MouseArea { id: kt; anchors.fill: parent; onClicked: win.press(modelData.k) }
                    }
                }
            }
        }
    }
}

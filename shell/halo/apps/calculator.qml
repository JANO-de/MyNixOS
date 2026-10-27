import QtQuick
import Quickshell
import qs.common

ShellRoot {
    AppWindow {
        id: win

        title: "Calculator"
        implicitWidth: 460
        implicitHeight: 720

        property string expr: ""
        property bool fresh: false
        readonly property string result: evalExpr(expr)

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
                spacing: 6
                Text {
                    width: parent.width
                    height: 60
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    text: win.expr === "" ? "0" : win.expr
                    color: AppTheme.dim
                    font.pixelSize: 28
                    elide: Text.ElideLeft
                }
                Text {
                    width: parent.width
                    height: 70
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    text: win.result
                    color: AppTheme.text
                    font.pixelSize: 48
                    font.weight: Font.DemiBold
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
                    model: ["C", "(", ")", "÷", "7", "8", "9", "×", "4", "5", "6", "-", "1", "2", "3", "+", "0", ".", "⌫", "="]

                    Rectangle {
                        required property string modelData
                        readonly property bool op: "÷×-+".indexOf(modelData) >= 0
                        width: parent.bw
                        height: parent.bh
                        radius: 28
                        color: modelData === "=" ? AppTheme.accent : (op ? AppTheme.accentSoft : (kt.pressed ? AppTheme.cardHigh : AppTheme.card))
                        scale: kt.pressed ? 0.95 : 1
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: modelData === "=" ? AppTheme.accentInk : AppTheme.text
                            font.pixelSize: 28
                        }
                        MouseArea { id: kt; anchors.fill: parent; onClicked: win.press(modelData) }
                    }
                }
            }
        }
    }
}

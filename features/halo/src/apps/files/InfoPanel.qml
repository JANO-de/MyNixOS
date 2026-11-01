import QtQuick
import Quickshell
import qs.common

// Details / preview of the selected item (or of the current folder).
Rectangle {
    id: ip
    required property var host
    readonly property var win: host
    property string target: ""
    property var rows: []
    property string mime: ""
    property string preview: ""
    property var ent: null
    readonly property string kind: ent ? Fx.kind(ent) : "folder"
    radius: 28
    color: AppTheme.low
    clip: true

    onTargetChanged: {
        rows = [];
        preview = "";
        if (target !== "" && visible)
            win.statOf(target, false, t => ip.parseStat(t));
    }
    Timer {
        interval: 120
        running: ip.visible
        repeat: true
        onTriggered: {
            const a = ip.win.activePane();
            if (!a)
                return;
            const s = a.selEntries();
            ip.ent = s.length === 1 ? s[0] : null;
            const t = s.length === 1 ? s[0].path : (s.length === 0 && !a.isPc ? a.path : "");
            if (t !== ip.target)
                ip.target = t;
        }
    }
    function parseStat(t) {
        const l = t.split("\n");
        if (l.length < 3)
            return;
        const f = l[0].split("|");
        mime = l[1];
        const r = [["Type", f[0]], ["Modified", (f[3] || "").substring(0, 16)], ["Permissions", f[1] + "  " + f[2]]];
        if (ent && !ent.dir)
            r.unshift(["Size", Fx.human(parseInt(f[4]))]);
        else
            r.unshift(["Items", l[2]]);
        r.push(["Path", target]);
        rows = r;
        preview = l.slice(4).join("\n");
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 18
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: col
            width: parent.width
            spacing: 14
            Item {
                width: parent.width
                height: 180
                RoundImg {
                    anchors.fill: parent
                    visible: ip.ent !== null && ip.kind === "image"
                    radius: 22
                    px: 600
                    source: ip.ent && ip.kind === "image" ? "file://" + ip.ent.path : ""
                }
                Ico {
                    visible: !(ip.ent && ip.kind === "image")
                    anchors.centerIn: parent
                    size: 110
                    name: Fx.ico(ip.kind)
                    color: ip.kind === "folder" ? AppTheme.accent : AppTheme.dim
                }
            }
            Text {
                width: parent.width
                text: ip.ent ? ip.ent.name : (ip.target === "" ? "Nothing selected" : Fx.base(ip.target))
                color: AppTheme.text
                font.pixelSize: 18
                font.weight: Font.DemiBold
                wrapMode: Text.WrapAnywhere
            }
            Repeater {
                model: ip.rows
                Column {
                    required property var modelData
                    width: col.width
                    Text { text: modelData[0]; color: AppTheme.dim; font.pixelSize: 12 }
                    Text { width: parent.width; text: modelData[1]; color: AppTheme.text; font.pixelSize: 14; wrapMode: Text.WrapAnywhere }
                }
            }
            Rectangle {
                visible: ip.preview !== ""
                width: parent.width
                height: pv.implicitHeight + 24
                radius: 18
                color: AppTheme.card
                Text {
                    id: pv
                    x: 12
                    y: 12
                    width: parent.width - 24
                    text: ip.preview
                    color: AppTheme.dim
                    font.pixelSize: 12
                    font.family: "monospace"
                    wrapMode: Text.Wrap
                    maximumLineCount: 14
                    elide: Text.ElideRight
                }
            }
        }
    }
}

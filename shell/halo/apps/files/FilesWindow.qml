import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

AppWindow {
    id: root
    title: "Files"
    heading: root.path === root.home ? "Home" : root.path.substring(root.path.lastIndexOf("/") + 1)
    canBack: root.path !== root.home
    onBackClicked: root.up()

    readonly property string home: AppTheme.home
    readonly property string trash: home + "/.local/share/Trash/files"
    property string path: home
    property var entries: []
    property bool showHidden: false
    property bool grid: true
    property var sel: []            // selected absolute paths
    property var clip: []           // copied / cut paths
    property bool cut: false
    property string dialog: ""      // "" | "mkdir" | "rename"
    readonly property bool inTrash: path.indexOf(trash) === 0
    readonly property var places: [
        { n: "Home", p: home }, { n: "Documents", p: home + "/Documents" }, { n: "Downloads", p: home + "/Downloads" },
        { n: "Pictures", p: home + "/Pictures" }, { n: "Music", p: home + "/Music" }, { n: "Videos", p: home + "/Videos" },
        { n: "Trash", p: trash }
    ]

    function go(p) {
        path = p;
        sel = [];
        refresh();
    }
    function up() {
        if (path === "/" || path === home)
            return;
        go(path.substring(0, path.lastIndexOf("/")) || "/");
    }
    function refresh() {
        lister.command = ["find", "-L", path, "-maxdepth", "1", "-mindepth", "1", "-printf", "%y\t%s\t%T@\t%f\n"];
        lister.running = false;
        lister.running = true;
    }
    function parse(t) {
        const out = [];
        for (const l of t.split("\n")) {
            const f = l.split("\t");
            if (f.length < 4 || (!showHidden && f[3].charAt(0) === "."))
                continue;
            const nm = f.slice(3).join("\t");
            out.push({ name: nm, path: (path === "/" ? "" : path) + "/" + nm, dir: f[0] === "d", size: parseInt(f[1]), mtime: parseFloat(f[2]) });
        }
        out.sort((a, b) => a.dir !== b.dir ? (a.dir ? -1 : 1) : a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: "base" }));
        entries = out;
    }
    function ext(n) {
        const i = n.lastIndexOf(".");
        return i < 0 ? "" : n.substring(i + 1).toLowerCase();
    }
    function kind(e) {
        if (e.dir)
            return "folder";
        const x = ext(e.name);
        if (["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg"].indexOf(x) >= 0)
            return "image";
        if (["mp3", "flac", "ogg", "wav", "m4a", "opus"].indexOf(x) >= 0)
            return "audio";
        if (["mp4", "mkv", "webm", "mov", "avi"].indexOf(x) >= 0)
            return "video";
        if (x === "pdf")
            return "pdf";
        if (["zip", "tar", "gz", "xz", "7z", "rar", "bz2", "zst"].indexOf(x) >= 0)
            return "archive";
        return "text";
    }
    function iconName(k) {
        return { folder: "folder", image: "image-x-generic", audio: "audio-x-generic", video: "video-x-generic", pdf: "application-pdf", archive: "package-x-generic", text: "text-x-generic" }[k];
    }
    function human(b) {
        if (b < 1024)
            return b + " B";
        const u = ["KB", "MB", "GB", "TB"];
        let i = -1;
        do {
            b /= 1024;
            i++;
        } while (b >= 1024 && i < 3);
        return b.toFixed(b < 10 ? 1 : 0) + " " + u[i];
    }
    function open(e) {
        if (e.dir) {
            go(e.path);
            return;
        }
        Quickshell.execDetached(["xdg-open", e.path]);
        // newest first, 20 max: read by the Recent files widget
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/.cache/halo\"; f=\"$HOME/.cache/halo/recent-files\"; { printf '%s\\n' \"$1\"; grep -vxF -- \"$1\" \"$f\" 2>/dev/null; } | head -20 > \"$f.tmp\" && mv \"$f.tmp\" \"$f\"", "sh", e.path]);
    }
    function isSel(p) {
        return sel.indexOf(p) >= 0;
    }
    function toggle(p) {
        const s = sel.slice();
        const i = s.indexOf(p);
        if (i >= 0)
            s.splice(i, 1);
        else
            s.push(p);
        sel = s;
    }
    function run(cmd) {
        op.command = cmd;
        op.running = false;
        op.running = true;
    }
    function doCopy(isCut) {
        clip = sel.slice();
        cut = isCut;
        sel = [];
    }
    function doPaste() {
        if (clip.length === 0)
            return;
        if (cut)
            run(["mv", "--backup=numbered", "-t", path, "--"].concat(clip));
        else
            run(["sh", "-c", "d=\"$1\"; shift; for f in \"$@\"; do cp -r --backup=numbered -- \"$f\" \"$d\"/; done", "sh", path].concat(clip));
        if (cut)
            clip = [];
    }
    function doDelete() {
        const s = sel;
        sel = [];
        if (inTrash)
            run(["rm", "-rf", "--"].concat(s));
        else
            run(["sh", "-c", "gio trash -- \"$@\" 2>/dev/null || rm -rf -- \"$@\"", "sh"].concat(s));
    }
    function submit(name) {
        const n = name.trim().replace(/\//g, "");
        if (n !== "") {
            if (dialog === "mkdir")
                run(["mkdir", "-p", "--", path + "/" + n]);
            else if (dialog === "rename" && sel.length === 1)
                run(["mv", "-n", "--", sel[0], path + "/" + n]);
        }
        dialog = "";
        sel = [];
    }

    Process {
        id: lister
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Process {
        id: op
        onExited: root.refresh()
    }
    Component.onCompleted: refresh()

    actions: [
        Pill { label: root.grid ? "List" : "Grid"; onClicked: root.grid = !root.grid },
        Pill { label: "Hidden"; on: root.showHidden; onClicked: { root.showHidden = !root.showHidden; root.refresh(); } },
        Pill { label: "New folder"; visible: !root.inTrash; onClicked: root.dialog = "mkdir" }
    ]

    // Sidebar
    Column {
        id: side
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        width: root.width >= 800 ? 190 : 0
        visible: width > 0
        spacing: 4
        Repeater {
            model: root.places
            Rectangle {
                required property var modelData
                width: side.width
                height: 44
                radius: 14
                color: root.path === modelData.p ? AppTheme.card : "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    text: parent.modelData.n
                    color: root.path === parent.modelData.p ? AppTheme.accent : AppTheme.text
                    font.pixelSize: 16
                }
                MouseArea { anchors.fill: parent; onClicked: root.go(parent.modelData.p) }
            }
        }
    }

    GridView {
        id: view
        anchors.left: side.visible ? side.right : parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.top: parent.top
        anchors.bottom: bottomBar.top
        clip: true
        cellWidth: root.grid ? 132 : width
        cellHeight: root.grid ? 148 : 64
        model: root.entries
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            id: cell
            required property var modelData
            readonly property string k: root.kind(modelData)
            readonly property bool picked: root.isSel(modelData.path)
            width: view.cellWidth
            height: view.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 16
                color: cell.picked ? AppTheme.cardHigh : "transparent"
                border.width: cell.picked ? 2 : 0
                border.color: AppTheme.accent
            }
            Item {
                id: ico
                x: root.grid ? (cell.width - 76) / 2 : 14
                y: root.grid ? 12 : 8
                width: root.grid ? 76 : 48
                height: width
                Image {
                    anchors.fill: parent
                    visible: cell.k !== "image"
                    source: Quickshell.iconPath(root.iconName(cell.k), "text-x-generic")
                    sourceSize: Qt.size(96, 96)
                    fillMode: Image.PreserveAspectFit
                }
                Image {
                    anchors.fill: parent
                    visible: cell.k === "image"
                    source: cell.k === "image" ? "file://" + cell.modelData.path : ""
                    sourceSize: Qt.size(160, 160)
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                }
            }
            Text {
                x: root.grid ? 8 : ico.x + ico.width + 14
                y: root.grid ? ico.y + ico.height + 8 : 10
                width: root.grid ? cell.width - 16 : cell.width - x - 120
                horizontalAlignment: root.grid ? Text.AlignHCenter : Text.AlignLeft
                text: cell.modelData.name
                color: AppTheme.text
                font.pixelSize: 14
                elide: Text.ElideMiddle
                maximumLineCount: root.grid ? 2 : 1
                wrapMode: root.grid ? Text.WrapAnywhere : Text.NoWrap
            }
            Text {
                visible: !root.grid
                x: ico.x + ico.width + 14
                y: 34
                text: cell.modelData.dir ? "Folder" : root.human(cell.modelData.size)
                color: AppTheme.dim
                font.pixelSize: 12
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.sel.length > 0 ? root.toggle(cell.modelData.path) : root.open(cell.modelData)
                onPressAndHold: root.toggle(cell.modelData.path)
            }
        }

        Text {
            visible: root.entries.length === 0
            anchors.centerIn: parent
            text: "Empty"
            color: AppTheme.dim
            font.pixelSize: 18
        }
    }

    // Bottom action bar (selection actions / paste)
    Row {
        id: bottomBar
        anchors.horizontalCenter: view.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        height: visible ? 52 : 0
        spacing: 8
        visible: root.sel.length > 0 || root.clip.length > 0
        Pill { visible: root.sel.length > 0; label: root.sel.length + " selected"; on: true; onClicked: root.sel = [] }
        Pill { visible: root.sel.length > 0 && !root.inTrash; label: "Copy"; onClicked: root.doCopy(false) }
        Pill { visible: root.sel.length > 0 && !root.inTrash; label: "Cut"; onClicked: root.doCopy(true) }
        Pill { visible: root.sel.length === 1 && !root.inTrash; label: "Rename"; onClicked: root.dialog = "rename" }
        Pill { visible: root.sel.length > 0; label: root.inTrash ? "Delete forever" : "Trash"; danger: true; onClicked: root.doDelete() }
        Pill { visible: root.sel.length === 0 && root.clip.length > 0 && !root.inTrash; label: "Paste " + root.clip.length; on: true; onClicked: root.doPaste() }
        Pill { visible: root.sel.length === 0 && root.clip.length > 0; label: "Clear"; onClicked: root.clip = [] }
    }

    // Name dialog (new folder / rename)
    Rectangle {
        anchors.fill: parent
        visible: root.dialog !== ""
        color: Qt.rgba(0, 0, 0, 0.55)
        MouseArea { anchors.fill: parent; onClicked: root.dialog = "" }
        Rectangle {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -parent.height * 0.15
            width: Math.min(460, parent.width - 40)
            height: 150
            radius: 28
            color: AppTheme.card
            Text {
                x: 24
                y: 16
                text: root.dialog === "mkdir" ? "New folder" : "Rename"
                color: AppTheme.dim
                font.pixelSize: 15
            }
            Rectangle {
                x: 20
                y: 46
                width: parent.width - 40
                height: 46
                radius: 14
                color: AppTheme.bg
                TextInput {
                    id: nameIn
                    anchors.fill: parent
                    anchors.margins: 12
                    color: AppTheme.text
                    font.pixelSize: 18
                    clip: true
                    focus: root.dialog !== ""
                    onAccepted: root.submit(text)
                }
            }
            Pill {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                label: "OK"
                on: true
                onClicked: root.submit(nameIn.text)
            }
            Pill {
                anchors.right: parent.right
                anchors.rightMargin: 100
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                label: "Cancel"
                onClicked: root.dialog = ""
            }
        }
        onVisibleChanged: {
            if (visible) {
                nameIn.text = root.dialog === "rename" && root.sel.length === 1 ? root.sel[0].substring(root.sel[0].lastIndexOf("/") + 1) : "";
                nameIn.forceActiveFocus();
                nameIn.selectAll();
            }
        }
    }
}

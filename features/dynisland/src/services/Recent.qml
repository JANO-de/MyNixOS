// Recently used files, read from ~/.local/share/recently-used.xbel (GTK/Qt apps write it).
// Recent.items = [{ path, name }] newest first. Only parsed while `watching`.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool watching: false
    property var items: []

    function parse(t) {
        const out = [], seen = {}, re = /href="file:\/\/([^"]+)"/g;
        let m;
        while ((m = re.exec(t)) !== null) {
            let p = m[1];
            try { p = decodeURIComponent(p) } catch (e) {}
            if (seen[p] || p.indexOf("/tmp/") === 0) continue;
            seen[p] = true;
            out.push({ path: p, name: p.substring(p.lastIndexOf("/") + 1) });
        }
        root.items = out.reverse().slice(0, 12);
    }
    FileView {
        id: fv
        path: root.watching ? Quickshell.env("HOME") + "/.local/share/recently-used.xbel" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }
}

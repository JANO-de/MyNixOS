import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string name: "data"
    property var fallback: []
    property var data: fallback
    readonly property string dir: Quickshell.env("HOME") + "/.local/share/halo"
    signal loaded

    function save() {
        Quickshell.execDetached(["mkdir", "-p", dir]);
        saveT.restart();
    }

    Timer {
        id: saveT
        interval: 400
        onTriggered: f.setText(JSON.stringify(root.data))
    }
    FileView {
        id: f
        path: root.dir + "/" + root.name + ".json"
        atomicWrites: true
        onLoaded: {
            try {
                root.data = JSON.parse(text());
            } catch (e) {}
            root.loaded();
        }
    }
}

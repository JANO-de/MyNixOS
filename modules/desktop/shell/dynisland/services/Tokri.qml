pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property bool visible: false
    property var items: []

    FileView {
        id: fv
        path: Config.dir + "/tokri.json"
        onLoaded: { try { root.items = JSON.parse(text()) } catch (e) { root.items = [] } }
    }

    function add(item) {
        const next = items.slice()
        next.push(item)
        items = next
        fv.setText(JSON.stringify(items))
    }

    function remove(index) {
        const next = items.slice()
        next.splice(index, 1)
        items = next
        fv.setText(JSON.stringify(items))
    }

    function clear() {
        items = []
        fv.setText("[]")
    }

    function toggle() { visible = !visible }
}

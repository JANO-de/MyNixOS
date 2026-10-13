// Icon name -> codepoint (generated at build time from the font; see default.nix).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    FileView { id: fv; path: Quickshell.env("DYN_ICON_MAP") || ""; blockLoading: true }
    property var warned: ({})
    function unknown(name) {                  // log each missing icon name once
        if (name === "" || warned[name]) return;
        warned[name] = true;
        console.warn("Icon: no glyph named '" + name + "' in the icon font (shows as text)");
    }
    Component.onCompleted: console.log("IconMap: " + Object.keys(map).length + " icons from '" + fv.path + "'")
    readonly property var map: { try { return JSON.parse(fv.text()) } catch (e) { return ({}) } }
}

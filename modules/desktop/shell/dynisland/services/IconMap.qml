// Icon name -> codepoint (generated at build time from the font; see default.nix).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    FileView { id: fv; path: Quickshell.env("DYN_ICON_MAP") || ""; blockLoading: true }
    readonly property var map: { try { return JSON.parse(fv.text()) } catch (e) { return ({}) } }
}

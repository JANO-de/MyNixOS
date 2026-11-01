import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Long-press menu of an app icon (Android TaskbarPopupController): split options first, then Halo extras.
// Android order: App info, Split left, Split right (split options are not shown in desktop windowing).
PanelWindow {
    id: root

    property string screenName: "" // plain string: reading `screen` inside `visible` makes a binding loop
    readonly property var item: UI.menuItem
    readonly property bool running: item ? item.windows.length > 0 : false

    readonly property var rows: {
        const r = [];
        if (!item)
            return r;
        // Android SystemShortcut.AppInfo comes first; here it opens Settings > Apps.
        r.push({ id: "info", label: "App info" });
        // Android TaskbarPopupController: split options are NOT shown in desktop windowing; there the menu
        // offers "New window" (NewWindowTaskbarShortcut: launches the app intent again, FLAG_ACTIVITY_MULTIPLE_TASK).
        if (Mode.tablet) {
            r.push({ id: "left", label: "Split left" });
            r.push({ id: "right", label: "Split right" });
        } else if (item.entry) {
            r.push({ id: "newwin", label: "New window" });
        }
        // Android ManageWindowsTaskbarShortcut: only for apps with several open instances.
        if (item.windows.length > 1)
            r.push({ id: "manage", label: "Manage windows" });
        r.push({ sep: true });
        if (item.pinIndex >= 0)
            r.push({ id: "unpin", label: "Remove from dock" });
        else if (item.entry)
            r.push({ id: "pin", label: "Pin to dock" });
        r.push({ id: "edit", label: "Edit dock" });
        if (running)
            r.push({ id: "close", label: item.windows.length > 1 ? "Close all windows" : "Close" });
        return r;
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    visible: UI.menuItem !== null && UI.menuScreen === screenName
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-appmenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function act(id) {
        const it = root.item;
        const scr = root.screen;
        const cx = UI.menuX;
        const top = UI.menuY;
        UI.closeAppMenu();
        if (!it)
            return;
        if (id === "left" || id === "right")
            UI.splitFromMenu(it, id, scr);
        else if (id === "info")
            UI.openAppInfo(it.entry ? it.entry.id : "");
        else if (id === "newwin")
            Home.launch(it.entry);
        else if (id === "manage")
            UI.openWindowsMenu(it, cx, top, root.screenName);
        else if (id === "pin")
            Apps.pin(it.entry);
        else if (id === "unpin")
            Apps.unpin(it.pinIndex);
        else if (id === "edit")
            UI.dockEditing = true;
        else if (id === "close")
            for (const w of it.windows)
                w.close();
    }

    // Backdrop: tap outside closes.
    MouseArea {
        anchors.fill: parent
        onClicked: UI.closeAppMenu()
    }

    Rectangle {
        id: card
        width: 264
        height: col.implicitHeight + 16
        x: Math.max(12, Math.min(root.width - width - 12, UI.menuX - width / 2))
        y: Math.max(12, UI.menuY - height)
        radius: 22
        color: Theme.glass
        border.color: Theme.glassStroke
        border.width: 1

        MouseArea { anchors.fill: parent } // swallow taps on the card

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8

            // Header: icon + name
            Item {
                width: col.width
                height: 52

                Image {
                    id: headIcon
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    source: root.item ? Apps.iconSource(root.item.icon) : ""
                    sourceSize: Qt.size(64, 64)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                Text {
                    anchors.left: headIcon.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.item ? root.item.name : ""
                    color: Theme.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            Repeater {
                model: root.rows

                Item {
                    id: rowItem
                    required property var modelData
                    width: col.width
                    height: modelData.sep ? 9 : 46

                    Rectangle {
                        visible: rowItem.modelData.sep === true
                        anchors.verticalCenter: parent.verticalCenter
                        x: 8
                        width: parent.width - 16
                        height: 1
                        color: Theme.glassStroke
                    }

                    Rectangle {
                        visible: rowItem.modelData.sep !== true
                        anchors.fill: parent
                        radius: 14
                        color: rowArea.pressed ? Qt.rgba(1, 1, 1, 0.14) : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: rowItem.modelData.label || ""
                            color: Theme.text
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            onClicked: root.act(rowItem.modelData.id)
                        }
                    }
                }
            }
        }
    }
}

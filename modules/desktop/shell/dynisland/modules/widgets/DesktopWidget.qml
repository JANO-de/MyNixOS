// =============================================================================
//  DesktopWidget — draggable glass card. Position is saved per `wid` in
//  Config.widgets.positions. Put your content inside as children.
//  TO ADD A WIDGET: instantiate this in DesktopWidgets.qml with a unique wid,
//  add its toggle in Config.widgets + Settings > Widgets.
// =============================================================================
import QtQuick
import qs.config
import qs.services

Rectangle {
    id: w
    required property string wid
    property real defX: 80
    property real defY: 120
    default property alias content: holder.data
    property string panel: ""          // island panel to open on right-click (see UiState.openPanel)

    readonly property var saved: Config.widgets.positions[wid]
    readonly property real baseX: saved ? saved.x : defX
    readonly property real baseY: saved ? saved.y : defY
    property point last: Qt.point(0, 0)

    x: baseX + (drag.active ? last.x : 0)
    y: baseY + (drag.active ? last.y : 0)
    implicitWidth: holder.childrenRect.width + 40
    implicitHeight: holder.childrenRect.height + 36
    radius: Config.widgets.cardRadius
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, Config.appearance.glassOpacity)
    border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.12)

    Item { id: holder; x: 20; y: 18; width: childrenRect.width; height: childrenRect.height }

    TapHandler { acceptedButtons: Qt.RightButton; enabled: w.panel !== ""; onTapped: UiState.openPanel(w.panel) }

    DragHandler {
        id: drag; target: null
        onTranslationChanged: w.last = translation
        onActiveChanged: if (!active) Config.setWidgetPos(w.wid, w.baseX + w.last.x, w.baseY + w.last.y)
    }
}

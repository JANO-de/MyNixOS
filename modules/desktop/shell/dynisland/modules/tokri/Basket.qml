import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

LazyLoader {
    active: Tokri.visible

    PanelWindow {
        anchors { right: true; bottom: true }
        margins { right: 24; bottom: 24 }
        width: 320
        height: 400
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Qt.rgba(0, 0, 0, 0.7)

            DropArea {
                anchors.fill: parent
                keys: ["text/plain", "text/uri-list", "application/x-qabstractitemmodeldatalist"]
                onDropped: (drop) => {
                    if (drop.hasText) Tokri.add({ type: "text", value: drop.text })
                    else if (drop.hasUrls) {
                        for (const u of drop.urls) Tokri.add({ type: "url", value: u.toString() })
                    }
                    drop.accept()
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "Tokri Basket"
                        color: "white"
                        font.bold: true
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: Tokri.items
                        delegate: Rectangle {
                            width: parent.width
                            height: 32
                            color: "transparent"
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                color: "white"
                                text: modelData.value || modelData.type
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            MouseArea {
                                anchors.fill: parent
                                drag.target: parent
                                onReleased: if (drag.active) { /* drag-out handled by OS */ }
                            }
                        }
                    }

                    RowLayout {
                        Button { text: "Clear"; onClicked: Tokri.clear() }
                        Button { text: "Close"; onClicked: Tokri.visible = false }
                    }
                }
            }
        }
    }
}

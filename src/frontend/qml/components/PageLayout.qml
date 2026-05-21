// Unified page layout: TopBar (back + title + actions) + Body (optional sidebar + content)
// Usage:
//   PageLayout {
//       title: "页面标题"
//       onBackRequested: stackView.pop()
//
//       topbarActions: RowLayout { ... }   // optional, placed in topbar
//       sidebarContent: ColumnLayout { ... } // optional, enables sidebar
//
//       // Main content (default property — any unnamed child goes here)
//       Flickable { anchors.fill: parent; ... }
//   }
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../dtk"

Item {
    id: root

    property string title: ""
    property Item topbarActions: null
    property Item sidebarContent: null
    property bool hasSidebar: sidebarContent !== null

    signal backRequested()

    // Reparent topbar actions into the topbar area
    onTopbarActionsChanged: {
        if (topbarActions) {
            Qt.callLater(function() { topbarActions.parent = topbarActionsRow })
        }
    }

    // Reparent sidebar content into the sidebar area
    onSidebarContentChanged: {
        if (sidebarContent) {
            sidebarContent.parent = sidebarContainer
            sidebarContent.anchors.fill = sidebarContainer
        }
    }

    // Default property: children go into the content area
    default property alias content: contentArea.data

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── TopBar (fixed 48px) ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "#ffffff"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Qt.rgba(0, 0, 0, 0.08)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 12

                RowLayout {
                    spacing: 2

                    Text {
                        text: "←"
                        font.pixelSize: 16
                        color: backArea.containsMouse ? "#0066cc" : Qt.rgba(0, 0, 0, 0.5)
                    }
                    Text {
                        text: qsTr("返回")
                        font.pixelSize: 13
                        color: backArea.containsMouse ? "#0066cc" : Qt.rgba(0, 0, 0, 0.5)
                    }

                    MouseArea {
                        id: backArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.backRequested()
                    }
                }

                Text {
                    text: root.title
                    font.pixelSize: 14
                    font.bold: true
                    color: Qt.rgba(0, 0, 0, 0.7)
                    visible: root.title !== ""
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    id: topbarActionsRow
                    spacing: 8
                    visible: root.topbarActions !== null
                }
            }
        }

        // ── Body ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Sidebar (optional)
                Rectangle {
                    id: sidebarFrame
                    Layout.preferredWidth: root.hasSidebar ? DTKStyle.settings.navigation.width : 0
                    Layout.fillHeight: true
                    visible: root.hasSidebar
                    color: Qt.rgba(0, 0, 0, 0.02)

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: Qt.rgba(0, 0, 0, 0.08)
                    }

                    Item {
                        id: sidebarContainer
                        anchors.fill: parent
                    }
                }

                // Content area
                Item {
                    id: contentArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}

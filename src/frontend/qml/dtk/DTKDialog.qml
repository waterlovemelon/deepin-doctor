// DTK Dialog - dialog container with title bar and button footer
// Pure QML reimplementation of org.deepin.dtk/Dialog
import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: dialog

    property string title: ""
    property alias contentItem: contentLoader.sourceComponent
    property alias footerItem: footerLoader.sourceComponent
    property int radius: DTKStyle.dialog.radius

    // Default size
    implicitWidth: 400
    implicitHeight: 300

    // Backdrop overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)

        MouseArea {
            anchors.fill: parent
            // Block clicks from passing through
        }
    }

    // Dialog body
    Rectangle {
        id: body
        anchors.centerIn: parent
        width: Math.min(dialog.width * 0.8, 540)
        height: Math.min(dialog.height * 0.8, 400)
        radius: dialog.radius
        color: "#ffffff"
        border.color: Qt.rgba(0, 0, 0, 0.08)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Title bar
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: DTKStyle.dialog.titleBarHeight

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16

                    Text {
                        text: dialog.title
                        font.pixelSize: 14
                        font.bold: true
                        color: Qt.rgba(0, 0, 0, 0.8)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Close button
                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24

                        Rectangle {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            radius: 10
                            color: closeMouseArea.containsMouse ? Qt.rgba(0, 0, 0, 0.1) : "transparent"

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 10
                                color: Qt.rgba(0, 0, 0, 0.5)
                            }
                        }

                        MouseArea {
                            id: closeMouseArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dialog.visible = false
                        }
                    }
                }

                // Bottom separator
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Qt.rgba(0, 0, 0, 0.05)
                }
            }

            // Content area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: DTKStyle.dialog.contentHMargin
                Layout.rightMargin: DTKStyle.dialog.contentHMargin

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                }
            }

            // Footer
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: footerLoader.active ? 50 : 0
                Layout.bottomMargin: DTKStyle.dialog.footerMargin

                // Top separator
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 1
                    color: Qt.rgba(0, 0, 0, 0.05)
                    visible: footerLoader.active
                }

                Loader {
                    id: footerLoader
                    anchors.fill: parent
                    anchors.topMargin: 8
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    active: dialog.footerItem !== null
                }
            }
        }
    }
}

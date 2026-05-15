import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    // The currently active (selected) module id
    property string activeModule: ""

    // Array of module objects: {id, name, icon, desc, status}
    //   id     - string module identifier (e.g. "network")
    //   name   - display name (e.g. "Network")
    //   icon   - emoji icon (e.g. "🌐")
    //   desc   - short description
    //   status - optional string: "ready", "planned", etc.
    property var modules: []

    signal moduleClicked(string moduleId)

    ListView {
        id: listView
        anchors.fill: parent
        clip: true
        spacing: 4
        model: modules

        delegate: Rectangle {
            id: delegateItem
            width: listView.width
            height: 56
            radius: 8
            color: isActive ? mainWindow.accentColor : mouseArea.containsMouse ? mainWindow.surfaceColor : "transparent"

            property bool isActive: modelData.id === root.activeModule

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.moduleClicked(modelData.id)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                // Icon box
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 6
                    color: isActive ? Qt.rgba(1, 1, 1, 0.2) : mainWindow.elevatedSurfaceColor

                    Label {
                        anchors.centerIn: parent
                        text: modelData.icon || ""
                        font.pixelSize: 16
                    }
                }

                // Name + description
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: modelData.name || modelData.id || ""
                        font.pixelSize: 13
                        font.bold: true
                        color: isActive ? "#ffffff" : mainWindow.textColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Label {
                        text: modelData.desc || ""
                        font.pixelSize: 11
                        color: isActive ? Qt.rgba(1, 1, 1, 0.75) : mainWindow.mutedTextColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: text !== ""
                    }
                }
            }
        }
    }
}

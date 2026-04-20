import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property var selectedModules: []
    property var allModules: []
    property bool allSelected: false
    property var moduleDescriptions: ({})
    property var recommendedModuleIds: ["network", "system", "logs"]

    signal selectionChanged(var modules)

    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: qsTr("Modules")
                font.pixelSize: 13
                font.bold: true
                color: mainWindow.mutedTextColor
            }

            Item { Layout.fillWidth: true }

            Label {
                text: qsTr("%1 selected").arg(selectedModules.length)
                font.pixelSize: 12
                color: mainWindow.accentColor
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                text: qsTr("All")
                font.pixelSize: 11
                padding: 4
                onClicked: selectAll()
            }

            Button {
                text: qsTr("None")
                font.pixelSize: 11
                padding: 4
                onClicked: deselectAll()
            }

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("Recommended")
                font.pixelSize: 11
                padding: 4
                onClicked: selectRecommended()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: moduleListView.contentHeight + 16
            color: Qt.rgba(0, 0, 0, 0)
            radius: mainWindow.radiusMd
            border.color: mainWindow.borderColor
            border.width: 1

            ListView {
                id: moduleListView
                anchors.fill: parent
                anchors.margins: 6
                clip: true
                spacing: 4
                model: allModules
                interactive: contentHeight > parent.height

                delegate: moduleCardDelegate
            }
        }
    }

    Component {
        id: moduleCardDelegate

        Rectangle {
            width: moduleListView.width
            implicitHeight: cardLayout.implicitHeight + 14
            radius: mainWindow.radiusSm
            color: isSelected
                    ? Qt.rgba(86 / 255, 179 / 255, 255 / 255, 0.12)
                    : Qt.rgba(24 / 255, 35 / 255, 59 / 255, 0.6)
            border.color: isSelected ? mainWindow.accentColor : "transparent"
            border.width: 1
            clip: true

            readonly property bool isSelected: selectedModules.indexOf(modelData) !== -1

            ColumnLayout {
                id: cardLayout
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: mainWindow.radiusSm
                        color: isSelected
                                ? Qt.rgba(86 / 255, 179 / 255, 255 / 255, 0.18)
                                : mainWindow.elevatedSurfaceColor
                        border.color: isSelected ? mainWindow.accentColor : mainWindow.borderColor
                        border.width: 1

                        Label {
                            anchors.centerIn: parent
                            text: (modelData || "").charAt(0).toUpperCase()
                            font.pixelSize: 16
                            font.bold: true
                            color: isSelected ? mainWindow.accentColor : mainWindow.mutedTextColor
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: modelData || ""
                            font.pixelSize: 13
                            font.bold: true
                            color: mainWindow.textColor
                            elide: Text.ElideRight
                        }

                        Label {
                            text: moduleDescriptions[modelData] || getDefaultDescription(modelData)
                            font.pixelSize: 11
                            color: mainWindow.mutedTextColor
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        radius: 10
                        color: isSelected ? mainWindow.accentColor : mainWindow.elevatedSurfaceColor
                        border.color: isSelected ? mainWindow.accentColor : mainWindow.borderColor
                        border.width: 1

                        Label {
                            anchors.centerIn: parent
                            text: isSelected ? "\u2713" : ""
                            font.pixelSize: 12
                            color: "#ffffff"
                            font.bold: true
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: toggleModule(modelData)
            }
        }
    }

    function getDefaultDescription(moduleName) {
        var descMap = {
            "network": qsTr("Interfaces, routes, DNS, connectivity"),
            "system": qsTr("OS version, kernel, hostname, uptime"),
            "environment": qsTr("Environment variables and locale"),
            "logs": qsTr("System and application logs")
        }
        return descMap[moduleName] || qsTr("System diagnostics module")
    }

    function setModules(modules) {
        allModules = modules.slice()
        selectedModules = modules.slice()
        moduleListView.model = modules
        allSelected = (modules.length > 0)
        root.selectionChanged(selectedModules)
    }

    function toggleModule(moduleName) {
        var nextSelection = selectedModules.slice()
        var idx = nextSelection.indexOf(moduleName)
        if (idx === -1) {
            nextSelection.push(moduleName)
        } else {
            nextSelection.splice(idx, 1)
        }
        selectedModules = nextSelection
        allSelected = (selectedModules.length === allModules.length)
        moduleListView.model = []
        moduleListView.model = allModules
        root.selectionChanged(selectedModules)
    }

    function selectAll() {
        selectedModules = allModules.slice()
        allSelected = true
        moduleListView.model = []
        moduleListView.model = allModules
        root.selectionChanged(selectedModules)
    }

    function deselectAll() {
        selectedModules = []
        allSelected = false
        moduleListView.model = []
        moduleListView.model = allModules
        root.selectionChanged(selectedModules)
    }

    function selectRecommended() {
        selectedModules = allModules.filter(function(m) {
            return recommendedModuleIds.indexOf(m) !== -1
        })
        allSelected = (selectedModules.length === allModules.length)
        moduleListView.model = []
        moduleListView.model = allModules
        root.selectionChanged(selectedModules)
    }
}

import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import "pages"
import "components"

ApplicationWindow {
    id: mainWindow

    visible: true
    width: 960
    height: 640
    minimumWidth: 800
    minimumHeight: 600
    title: qsTr("Deepin Doctor")
    color: backgroundColor

    // Light theme colors
    readonly property color backgroundColor: "#ffffff"
    readonly property color surfaceColor: "#f5f5f5"
    readonly property color elevatedSurfaceColor: "#e8e8e8"
    readonly property color borderColor: "#d0d0d0"
    readonly property color textColor: "#1a1a1a"
    readonly property color mutedTextColor: "#666666"
    readonly property color accentColor: "#0066cc"
    readonly property color successColor: "#2e7d32"
    readonly property color warningColor: "#ef6c00"
    readonly property color errorColor: "#c62828"

    property var exportData: null

    function goBack() {
        if (stackView.depth > 1)
            stackView.pop()
    }

    StackView {
        id: stackView
        anchors.fill: parent
        clip: true
        initialItem: homePageComponent
    }

    Component {
        id: homePageComponent

        HomePage {
            onModuleClicked: {
                stackView.push(modulePageComponent, { moduleId: arguments[0] })
            }
        }
    }

    Component {
        id: modulePageComponent

        ModulePage {
            onBackRequested: mainWindow.goBack()
            onModuleSwitchRequested: {
                this.moduleId = arguments[0]
            }
            onExportRequested: {
                mainWindow.exportData = arguments[0]
                stackView.push(exportPageComponent)
            }
        }
    }

    Component {
        id: exportPageComponent

        ExportPage {
            exportData: mainWindow.exportData
            onBackRequested: mainWindow.goBack()
            onExportCompleted: {
                console.log("Export completed:", arguments[0])
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: stackView.depth > 1
        onActivated: mainWindow.goBack()
    }
}

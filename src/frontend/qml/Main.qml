import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
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

    palette.window: backgroundColor
    palette.windowText: textColor
    palette.base: "#ffffff"
    palette.text: textColor
    palette.button: surfaceColor
    palette.buttonText: textColor
    palette.mid: borderColor
    palette.highlight: accentColor
    palette.highlightedText: "#ffffff"

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
            onModuleClicked: function(moduleId) {
                if (moduleId === "keyring") {
                    stackView.push(keyringPageComponent)
                } else {
                    stackView.push(modulePageComponent, { moduleId: moduleId })
                }
            }
        }
    }

    Component {
        id: keyringPageComponent

        KeyringPage {
            onBackRequested: mainWindow.goBack()
        }
    }

    Component {
        id: modulePageComponent

        ModulePage {
            onBackRequested: mainWindow.goBack()
            onModuleSwitchRequested: function(moduleId) {
                this.moduleId = moduleId
            }
            onExportRequested: function(resultData) {
                mainWindow.exportData = resultData
                stackView.push(exportPageComponent)
            }
        }
    }

    Component {
        id: exportPageComponent

        ExportPage {
            exportData: mainWindow.exportData
            onBackRequested: mainWindow.goBack()
            onExportCompleted: function(outputPath) {
                console.log("Export completed:", outputPath)
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: stackView.depth > 1
        onActivated: mainWindow.goBack()
    }
}

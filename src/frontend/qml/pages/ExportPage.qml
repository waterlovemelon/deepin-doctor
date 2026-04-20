import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

/**
 * Export page — Console Luxe design
 */
Item {
    id: root

    property var exportData: null
    property bool isExporting: false
    property real exportProgress: 0.0

    signal backRequested()
    signal exportCompleted(string outputPath)

    FileDialog {
        id: fileDialog
        title: qsTr("Select Export Location")
        selectExisting: false
        defaultSuffix: "tar.gz"
        nameFilters: ["Archive files (*.tar.gz)", "All files (*)"]
        onAccepted: {
            var p = fileUrl.toString()
            if (p.startsWith("file://")) p = p.substring(7)
            pathField.text = decodeURIComponent(p)
        }
    }

    MessageDialog {
        id: successDialog
        title: qsTr("Export Successful")
        text: msgText
        standardButtons: StandardButton.Ok
        property string msgText: ""
        onAccepted: root.exportCompleted(successDialog.exportPath)
        property string exportPath: ""
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 20

        // Header
        ColumnLayout {
            spacing: 6

            Label {
                text: qsTr("Export Results")
                font.pixelSize: 22
                font.bold: true
                color: mainWindow.textColor
            }

            Label {
                text: qsTr("Save diagnostic results as a compressed archive")
                font.pixelSize: 13
                color: mainWindow.mutedTextColor
            }
        }

        // Export Path section header
        Label {
            text: qsTr("Export Path")
            font.pixelSize: 13
            font.bold: true
            color: mainWindow.textColor
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: mainWindow.borderColor
            Layout.bottomMargin: 10
        }

        // Path input row
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: qsTr("File Path:")
                font.pixelSize: 13
                color: mainWindow.mutedTextColor
                Layout.preferredWidth: 80
            }

            TextField {
                id: pathField
                Layout.fillWidth: true
                placeholderText: qsTr("Select export location...")
                text: getDefaultExportPath()
                font.pixelSize: 13
                color: mainWindow.textColor
                placeholderTextColor: mainWindow.mutedTextColor
                background: Rectangle {
                    color: mainWindow.elevatedSurfaceColor
                    border.color: mainWindow.borderColor
                    border.width: 1
                    radius: mainWindow.radiusSm
                }
            }

            Button {
                text: qsTr("Browse...")
                font.pixelSize: 13
                padding: 8
                background: Rectangle {
                    color: mainWindow.elevatedSurfaceColor
                    radius: mainWindow.radiusSm
                    border.color: mainWindow.borderColor
                    border.width: 1
                }
                contentItem: Label {
                    text: parent.text
                    color: mainWindow.accentColor
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: fileDialog.open()
            }
        }

        // Archive format hint
        Label {
            text: qsTr("Results will be exported as a compressed archive (.tar.gz)")
            font.pixelSize: 11
            color: mainWindow.mutedTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.leftMargin: 90
        }

        Label {
            text: qsTr("Current export packages collected diagnostics into a single archive.")
            font.pixelSize: 12
            color: mainWindow.mutedTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.topMargin: 10
        }

        // Progress section
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: progressCol.implicitHeight + 32
            color: mainWindow.surfaceColor
            border.color: mainWindow.borderColor
            border.width: 1
            radius: mainWindow.radiusMd
            visible: isExporting || exportProgress > 0

            ColumnLayout {
                id: progressCol
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: qsTr("Export Progress")
                        font.pixelSize: 13
                        font.bold: true
                        color: mainWindow.textColor
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: qsTr("%1%").arg(Math.round(exportProgress * 100))
                        font.pixelSize: 13
                        font.bold: true
                        color: mainWindow.accentColor
                    }
                }

                ProgressBar {
                    Layout.fillWidth: true
                    value: exportProgress
                    from: 0
                    to: 1
                }

                Label {
                    id: exportStatusText
                    text: qsTr("Starting export...")
                    font.pixelSize: 12
                    color: mainWindow.mutedTextColor
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }

        // Action bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: qsTr("Back")
                font.pixelSize: 13
                padding: 10
                enabled: !isExporting
                background: Rectangle {
                    color: mainWindow.elevatedSurfaceColor
                    radius: mainWindow.radiusSm
                    border.color: mainWindow.borderColor
                    border.width: 1
                }
                contentItem: Label {
                    text: parent.text
                    color: mainWindow.textColor
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: backRequested()
            }

            Item { Layout.fillWidth: true }

            Button {
                id: exportButton
                text: qsTr("Export Results")
                font.pixelSize: 13
                font.bold: true
                padding: 10
                enabled: !isExporting && pathField.text !== "" && exportData !== null
                background: Rectangle {
                    color: parent.enabled ? mainWindow.accentColor : mainWindow.borderColor
                    radius: mainWindow.radiusSm
                }
                contentItem: Label {
                    text: parent.text
                    color: parent.enabled ? "#0b1020" : mainWindow.mutedTextColor
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: startExport()
            }
        }
    }

    function getDefaultExportPath() {
        var homePath = backend.homePath()
        var timestamp = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss")
        return homePath + "/deepin-doctor-export-" + timestamp + ".tar.gz"
    }

    function startExport() {
        if (!exportData) {
            console.error("No export data available")
            return
        }

        isExporting = true
        exportProgress = 0
        exportStatusText.text = qsTr("Starting export...")

        var payload = ""
        try {
            payload = JSON.stringify(exportData)
        } catch (e) {
            exportStatusText.text = qsTr("Export failed!")
            isExporting = false
            return
        }

        var outputPath = pathField.text
        var success = backend.exportResult(payload, outputPath)

        if (success) {
            finishExport()
        } else {
            exportStatusText.text = qsTr("Export failed!")
            isExporting = false
        }
    }

    function finishExport() {
        isExporting = false
        exportProgress = 1.0
        exportStatusText.text = qsTr("Export completed successfully!")
        successDialog.exportPath = pathField.text
        successDialog.msgText = qsTr("Results have been exported to:\n%1").arg(pathField.text)
        successDialog.open()
    }

    Component.onCompleted: {
        pathField.text = getDefaultExportPath()
    }
}

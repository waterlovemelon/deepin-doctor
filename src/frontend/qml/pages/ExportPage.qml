import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

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
        anchors.margins: 16
        spacing: 16

        // Header
        Label {
            text: qsTr("Export Results")
            font.bold: true
            font.pixelSize: 16
        }

        // Path input
        GroupBox {
            title: qsTr("Export Path")
            Layout.fillWidth: true

            RowLayout {
                anchors.fill: parent
                spacing: 8

                TextField {
                    id: pathField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Select export location...")
                    text: getDefaultExportPath()
                }

                Button {
                    text: qsTr("Browse...")
                    onClicked: fileDialog.open()
                }
            }
        }

        Label {
            text: qsTr("Results will be exported as a compressed archive (.tar.gz)")
            color: mainWindow.mutedTextColor
            font.pixelSize: 11
        }

        // Progress section
        GroupBox {
            Layout.fillWidth: true
            visible: isExporting || exportProgress > 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: qsTr("Export Progress")
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: qsTr("%1%").arg(Math.round(exportProgress * 100))
                        font.bold: true
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
                    color: mainWindow.mutedTextColor
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Action bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                text: qsTr("Back")
                enabled: !isExporting
                onClicked: backRequested()
            }

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("Export Results")
                enabled: !isExporting && pathField.text !== "" && exportData !== null
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

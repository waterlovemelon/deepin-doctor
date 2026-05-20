import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import "../components"
import "../dtk"

PageLayout {
    id: root

    title: qsTr("导出结果")

    property var exportData: null
    property bool isExporting: false
    property real exportProgress: 0.0

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

    // ── Content ──
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        DTKBoxPanel {
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Text { text: qsTr("Export Path"); font.bold: true; font.pixelSize: 13; color: Qt.rgba(0, 0, 0, 0.7) }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    DTKTextField {
                        id: pathField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Select export location...")
                        text: getDefaultExportPath()
                    }

                    DTKButton {
                        text: qsTr("Browse...")
                        onClicked: fileDialog.open()
                    }
                }

                Text {
                    text: qsTr("Results will be exported as a compressed archive (.tar.gz)")
                    color: Qt.rgba(0, 0, 0, 0.4)
                    font.pixelSize: 11
                }
            }
        }

        DTKBoxPanel {
            Layout.fillWidth: true
            visible: isExporting || exportProgress > 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: qsTr("Export Progress"); font.bold: true; color: mainWindow.textColor }
                    Item { Layout.fillWidth: true }
                    Text { text: qsTr("%1%").arg(Math.round(exportProgress * 100)); font.bold: true; color: DTKStyle.highlightColor }
                }

                DTKProgressBar { Layout.fillWidth: true; value: exportProgress; from: 0; to: 1 }
                Text { id: exportStatusText; text: qsTr("Starting export..."); color: Qt.rgba(0, 0, 0, 0.4) }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }
            DTKButton {
                text: qsTr("Export Results")
                highlighted: true
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
        if (!exportData) { console.error("No export data available"); return }
        isExporting = true; exportProgress = 0; exportStatusText.text = qsTr("Starting export...")
        var payload = ""
        try { payload = JSON.stringify(exportData) } catch (e) { exportStatusText.text = qsTr("Export failed!"); isExporting = false; return }
        var outputPath = pathField.text
        var success = backend.exportResult(payload, outputPath)
        if (success) finishExport()
        else { exportStatusText.text = qsTr("Export failed!"); isExporting = false }
    }

    function finishExport() {
        isExporting = false; exportProgress = 1.0; exportStatusText.text = qsTr("Export completed successfully!")
        successDialog.exportPath = pathField.text
        successDialog.msgText = qsTr("Results have been exported to:\n%1").arg(pathField.text)
        successDialog.open()
    }

    Component.onCompleted: { pathField.text = getDefaultExportPath() }
}

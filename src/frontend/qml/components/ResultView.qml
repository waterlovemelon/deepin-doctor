import QtQuick 2.11
import QtQuick.Controls 2.4 as Controls
import QtQuick.Layouts 1.11
import "../dtk"

Item {
    id: root

    property var resultData: null
    property string resultText: ""
    property bool resultTextExplicitlySet: false
    property string derivedResultText: resultData ? JSON.stringify(resultData, null, 2) : ""
    property var resultKeys: (resultData && typeof resultData === 'object') ? Object.keys(resultData) : []
    property bool showRawJson: true

    onResultDataChanged: {
        if (!resultTextExplicitlySet) {
            resultText = resultData ? JSON.stringify(resultData, null, 2) : ""
        }
    }

    implicitHeight: contentColumn.implicitHeight

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        width: root.width
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            DTKTabBar {
                id: resultTabBar
                Layout.fillWidth: true
                currentIndex: root.showRawJson ? 1 : 0
                model: [qsTr("Summary"), qsTr("Raw")]
            }

            DTKButton {
                text: qsTr("Copy")
                onClicked: copyToClipboard()
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: resultTabBar.currentIndex

            // Summary view
            ListView {
                id: summaryView
                clip: true
                spacing: 4
                model: resultKeys

                delegate: DTKItemDelegate {
                    width: summaryView.width
                    height: expanded ? expandedContent.height + 48 : 48

                    property bool expanded: false

                    contentItem: ColumnLayout {
                        spacing: 4

                        RowLayout {
                            spacing: 8

                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: getStatusColor(resultData[modelData])
                            }

                            Text {
                                text: getModuleName(modelData)
                                font.bold: true
                                font.pixelSize: 13
                                color: mainWindow.textColor
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: expanded ? "▼" : "▶"
                                color: Qt.rgba(0, 0, 0, 0.4)
                                font.pixelSize: 10
                            }
                        }

                        Text {
                            text: getModuleSummary(modelData)
                            color: Qt.rgba(0, 0, 0, 0.4)
                            visible: text !== ""
                            wrapMode: Text.WordWrap
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            id: expandedContent
                            Layout.fillWidth: true
                            Layout.preferredHeight: 200
                            visible: expanded
                            color: "#ffffff"
                            border.color: Qt.rgba(0, 0, 0, 0.08)
                            border.width: 1
                            radius: DTKStyle.control.radius

                            Controls.ScrollView {
                                anchors.fill: parent
                                anchors.margins: 4
                                Controls.ScrollBar.vertical: DTKScrollBar { }
                                DTKTextArea {
                                    text: resultData[modelData] ? JSON.stringify(resultData[modelData], null, 2) : ""
                                    readOnly: true; selectByMouse: true; wrapMode: TextEdit.WrapAnywhere
                                    font.family: "monospace"; font.pixelSize: 11
                                }
                            }
                        }
                    }

                    onClicked: expanded = !expanded
                }

                Text {
                    anchors.centerIn: parent
                    visible: resultKeys.length === 0
                    text: qsTr("No results yet")
                    color: Qt.rgba(0, 0, 0, 0.4)
                }
            }

            // Raw view
            Controls.ScrollView {
                Controls.ScrollBar.vertical: DTKScrollBar { }
                DTKTextArea {
                    id: rawTextArea
                    text: resultText !== "" ? resultText : derivedResultText
                    readOnly: true; selectByMouse: true; wrapMode: TextEdit.WrapAnywhere
                    font.family: "monospace"; font.pixelSize: 12
                }
            }
        }

        Text {
            id: statusLabel
            Layout.fillWidth: true
            text: ""
            color: mainWindow.successColor
            visible: text !== ""
        }
    }

    function getStatusColor(data) {
        if (!data) return Qt.rgba(0, 0, 0, 0.1)
        var lvl = data.level || data.status || ""
        if (lvl === "ok" || lvl === "success") return mainWindow.successColor
        if (lvl === "warning") return mainWindow.warningColor
        if (lvl === "error" || lvl === "fail") return mainWindow.errorColor
        return Qt.rgba(0, 0, 0, 0.1)
    }

    function getModuleName(key) {
        var d = resultData[key]
        return (d && d.name) ? d.name : key
    }

    function getModuleSummary(key) {
        var d = resultData[key]
        if (!d) return ""
        return d.description || d.message || d.summary || ""
    }

    function setResult(data) {
        resultTextExplicitlySet = false
        resultData = data
        resultText = data ? JSON.stringify(data, null, 2) : ""
    }

    function setResultText(text) {
        resultTextExplicitlySet = true
        resultText = text
        try { resultData = JSON.parse(text) } catch (e) { resultData = null }
    }

    function copyToClipboard() {
        var txt = resultTabBar.currentIndex === 1
            ? (resultText !== "" ? resultText : derivedResultText)
            : (resultData ? JSON.stringify(resultData, null, 2) : "")
        if (txt) {
            rawTextArea.selectAll(); rawTextArea.copy(); rawTextArea.deselect()
            statusLabel.text = qsTr("Copied to clipboard!")
            copyTimer.restart()
        }
    }

    Timer { id: copyTimer; interval: 2000; onTriggered: statusLabel.text = "" }
}

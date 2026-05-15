import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

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

        // Toolbar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TabBar {
                id: resultTabBar
                Layout.fillWidth: true
                currentIndex: root.showRawJson ? 1 : 0

                TabButton {
                    text: qsTr("Summary")
                    width: implicitWidth
                }

                TabButton {
                    text: qsTr("Raw")
                    width: implicitWidth
                }
            }

            Button {
                text: qsTr("Copy")
                onClicked: copyToClipboard()
            }
        }

        // Content area
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

                delegate: ItemDelegate {
                    width: summaryView.width
                    height: expanded ? expandedContent.height + 48 : 48

                    property bool expanded: false

                    contentItem: ColumnLayout {
                        spacing: 4

                        RowLayout {
                            spacing: 8

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: getStatusColor(resultData[modelData])
                            }

                            Label {
                                text: getModuleName(modelData)
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: expanded ? "▼" : "▶"
                                color: mainWindow.mutedTextColor
                            }
                        }

                        Label {
                            text: getModuleSummary(modelData)
                            color: mainWindow.mutedTextColor
                            visible: text !== ""
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // Expanded content
                        Rectangle {
                            id: expandedContent
                            Layout.fillWidth: true
                            Layout.preferredHeight: 200
                            visible: expanded
                            color: palette.base
                            border.color: palette.mid
                            border.width: 1

                            ScrollView {
                                anchors.fill: parent
                                anchors.margins: 4

                                TextArea {
                                    text: resultData[modelData]
                                        ? JSON.stringify(resultData[modelData], null, 2)
                                        : ""
                                    readOnly: true
                                    selectByMouse: true
                                    wrapMode: TextEdit.WrapAnywhere
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }

                    onClicked: expanded = !expanded
                }

                Label {
                    anchors.centerIn: parent
                    visible: resultKeys.length === 0
                    text: qsTr("No results yet")
                    color: mainWindow.mutedTextColor
                }
            }

            // Raw view
            ScrollView {
                TextArea {
                    id: rawTextArea
                    text: resultText !== "" ? resultText : derivedResultText
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAnywhere
                    font.family: "monospace"
                    font.pixelSize: 12
                }
            }
        }

        // Status label
        Label {
            id: statusLabel
            Layout.fillWidth: true
            text: ""
            color: mainWindow.successColor
            visible: text !== ""
        }
    }

    // Helper functions
    function getStatusColor(data) {
        if (!data) return palette.mid
        var lvl = data.level || data.status || ""
        if (lvl === "ok" || lvl === "success") return mainWindow.successColor
        if (lvl === "warning") return mainWindow.warningColor
        if (lvl === "error" || lvl === "fail") return mainWindow.errorColor
        return palette.mid
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

    // Public API
    function setResult(data) {
        resultTextExplicitlySet = false
        resultData = data
        resultText = data ? JSON.stringify(data, null, 2) : ""
    }

    function setResultText(text) {
        resultTextExplicitlySet = true
        resultText = text
        try {
            resultData = JSON.parse(text)
        } catch (e) {
            resultData = null
        }
    }

    function copyToClipboard() {
        var txt = resultTabBar.currentIndex === 1
            ? (resultText !== "" ? resultText : derivedResultText)
            : (resultData ? JSON.stringify(resultData, null, 2) : "")
        if (txt) {
            rawTextArea.selectAll()
            rawTextArea.copy()
            rawTextArea.deselect()
            statusLabel.text = qsTr("Copied to clipboard!")
            copyTimer.restart()
        }
    }

    Timer {
        id: copyTimer
        interval: 2000
        onTriggered: statusLabel.text = ""
    }
}

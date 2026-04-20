import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * Result display component — Console Luxe design
 * Summary (expandable cards) + Raw JSON tabs
 */
Item {
    id: root

    // Result data (parsed JSON object)
    property var resultData: null
    // Raw JSON string
    property string resultText: ""
    property bool resultTextExplicitlySet: false
    property string derivedResultText: resultData ? JSON.stringify(resultData, null, 2) : ""
    property var resultKeys: (resultData && typeof resultData === 'object') ? Object.keys(resultData) : []
    property int summaryItemCount: summaryRepeater.count
    // Default tab: true = Raw, false = Summary
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
        spacing: 10

        // Toolbar: tabs + copy button
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TabBar {
                id: resultTabBar
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                currentIndex: root.showRawJson ? 1 : 0

                background: Rectangle { color: "transparent" }

                TabButton {
                    text: qsTr("Summary")
                    font.pixelSize: 13
                    width: implicitWidth + 16

                    background: Rectangle {
                        color: resultTabBar.currentIndex === 0
                            ? Qt.rgba(0.34, 0.70, 1.0, 0.12)
                            : "transparent"
                        radius: mainWindow.radiusSm
                    }

                    contentItem: Label {
                        text: parent.text
                        color: resultTabBar.currentIndex === 0
                            ? mainWindow.accentColor
                            : mainWindow.textColor
                        font.pixelSize: 13
                        font.bold: resultTabBar.currentIndex === 0
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                TabButton {
                    text: qsTr("Raw")
                    font.pixelSize: 13
                    width: implicitWidth + 16

                    background: Rectangle {
                        color: resultTabBar.currentIndex === 1
                            ? Qt.rgba(0.34, 0.70, 1.0, 0.12)
                            : "transparent"
                        radius: mainWindow.radiusSm
                    }

                    contentItem: Label {
                        text: parent.text
                        color: resultTabBar.currentIndex === 1
                            ? mainWindow.accentColor
                            : mainWindow.textColor
                        font.pixelSize: 13
                        font.bold: resultTabBar.currentIndex === 1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Button {
                id: copyBtn
                text: qsTr("Copy")
                font.pixelSize: 12
                padding: 6
                background: Rectangle {
                    color: mainWindow.elevatedSurfaceColor
                    radius: mainWindow.radiusSm
                    border.color: mainWindow.borderColor
                    border.width: 1
                }
                contentItem: Label {
                    text: parent.text
                    color: mainWindow.accentColor
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: copyToClipboard()
            }
        }

        // Tip label
        Label {
            Layout.fillWidth: true
            text: qsTr("Tip: JSON format with syntax highlighting")
            font.pixelSize: 11
            color: mainWindow.mutedTextColor
        }

        // Content area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 400
            width: parent.width
            height: 400
            color: mainWindow.elevatedSurfaceColor
            border.color: mainWindow.borderColor
            border.width: 1
            radius: mainWindow.radiusMd
            clip: true

            // Summary view (tab 0)
            Flickable {
                id: summaryView
                anchors.fill: parent
                anchors.margins: 12
                visible: resultTabBar.currentIndex === 0
                clip: true
                contentWidth: width
                contentHeight: summaryColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: summaryColumn
                    objectName: "summaryColumn"
                    width: summaryView.width
                    spacing: 10

                    Repeater {
                        id: summaryRepeater
                        model: resultKeys

                        delegate: Item {
                            id: cardDelegate
                            objectName: "summaryCardDelegate"
                            width: summaryColumn.width
                            implicitHeight: cardRect.implicitHeight + (expanded ? expandedArea.implicitHeight + 8 : 0)
                            height: implicitHeight

                            property bool expanded: false

                            function getStatusColor(data) {
                                if (!data) return mainWindow.borderColor
                                var lvl = data.level || data.status || ""
                                if (lvl === "ok" || lvl === "success") return mainWindow.successColor
                                if (lvl === "warning") return mainWindow.warningColor
                                if (lvl === "error" || lvl === "fail") return mainWindow.errorColor
                                return mainWindow.borderColor
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

                            Rectangle {
                                id: cardRect
                                objectName: "summaryCardRect"
                                anchors.left: parent.left
                                anchors.right: parent.right
                                color: mainWindow.surfaceColor
                                border.color: mainWindow.borderColor
                                border.width: 1
                                radius: mainWindow.radiusMd
                                implicitHeight: cardColumn.implicitHeight + 24

                                Column {
                                    id: cardColumn
                                    x: 12
                                    y: 12
                                    width: cardRect.width - 24
                                    spacing: 6

                                    Row {
                                        spacing: 10
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        Rectangle {
                                            width: 8; height: 8; radius: 4
                                            color: getStatusColor(resultData[modelData])
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Label {
                                            text: getModuleName(modelData)
                                            color: mainWindow.textColor
                                            font.pixelSize: 13
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Label {
                                        text: getModuleSummary(modelData)
                                        color: mainWindow.mutedTextColor
                                        font.pixelSize: 12
                                        wrapMode: Text.WordWrap
                                        width: cardColumn.width
                                        visible: text !== ""
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: cardDelegate.expanded = !cardDelegate.expanded
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }

                            Item {
                                id: expandedArea
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: cardRect.bottom
                                anchors.topMargin: 8
                                implicitHeight: expandedContent.implicitHeight + 16
                                height: cardDelegate.expanded ? implicitHeight : 0
                                visible: height > 0
                                clip: true

                                Rectangle {
                                    id: expandedContent
                                    anchors.fill: parent
                                    color: mainWindow.elevatedSurfaceColor
                                    border.color: mainWindow.borderColor
                                    border.width: 1
                                    radius: mainWindow.radiusSm
                                    implicitHeight: expandedJsonArea.implicitHeight + 20

                                    TextArea {
                                        id: expandedJsonArea
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        text: resultData[modelData]
                                            ? JSON.stringify(resultData[modelData], null, 2)
                                            : ""
                                        readOnly: true
                                        selectByMouse: true
                                        wrapMode: TextEdit.WrapAnywhere
                                        font.family: "monospace"
                                        font.pixelSize: 11
                                        color: mainWindow.textColor
                                        background: Rectangle { color: "transparent" }
                                    }
                                }
                            }
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: resultKeys.length === 0
                    text: qsTr("No results yet")
                    color: mainWindow.mutedTextColor
                    font.pixelSize: 14
                }
            }

            // Raw view (tab 1)
            ScrollView {
                anchors.fill: parent
                anchors.margins: 12
                visible: resultTabBar.currentIndex === 1

                TextArea {
                    id: rawTextArea
                    text: resultText !== "" ? resultText : derivedResultText
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAnywhere
                    font.family: "monospace"
                    font.pixelSize: 12
                    color: mainWindow.textColor
                    background: Rectangle { color: "transparent" }
                }
            }
        }

        // Clipboard status label
        Label {
            id: statusLabel
            Layout.fillWidth: true
            text: ""
            color: mainWindow.successColor
            font.pixelSize: 12
            visible: text !== ""
        }
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

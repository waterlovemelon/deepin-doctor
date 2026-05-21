import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import "../components"
import "../dtk"

Item {
    id: root

    property string currentTaskId: ""
    property bool isCollecting: false
    property bool isDetecting: false
    property real collectProgress: 0.0
    property string currentModule: ""
    property var collectResult: null
    property var detectResult: null

    signal exportRequested(var resultData)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Left: module selection sidebar
        ColumnLayout {
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            spacing: 12

            DTKBoxPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: qsTr("Modules")
                        font.pixelSize: 14
                        font.bold: true
                        color: mainWindow.textColor
                    }

                    Text {
                        text: qsTr("Select which system areas to inspect.")
                        font.pixelSize: 11
                        color: mainWindow.mutedTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    ModuleSelector {
                        id: moduleSelector
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Component.onCompleted: {
                            var modules = backend.listModules()
                            setModules(modules)
                        }

                        onSelectionChanged: updateActionState()
                    }
                }
            }

            // Selection summary
            Text {
                text: moduleSelector.selectedModules.length > 0
                      ? qsTr("%1 module(s) selected").arg(moduleSelector.selectedModules.length)
                      : qsTr("No modules selected")
                font.pixelSize: 11
                color: mainWindow.mutedTextColor
            }
        }

        // Right: action + results column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // Action bar
            DTKBoxPanel {
                Layout.fillWidth: true

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: isCollecting ? qsTr("Collecting...") : qsTr("Ready")
                        font.bold: true
                        font.pixelSize: 13
                        color: mainWindow.textColor
                    }

                    Item { Layout.fillWidth: true }

                    DTKButton {
                        text: qsTr("Collect")
                        enabled: !isCollecting && !isDetecting && moduleSelector.selectedModules.length > 0
                        onClicked: startCollection()
                    }

                    DTKButton {
                        text: qsTr("Detect")
                        enabled: !isCollecting && !isDetecting && moduleSelector.selectedModules.length > 0
                        onClicked: startDetection()
                    }

                    DTKButton {
                        text: qsTr("Export")
                        highlighted: true
                        enabled: !isCollecting && !isDetecting && collectResult !== null
                        onClicked: exportRequested(collectResult)
                    }
                }
            }

            // Progress area
            DTKBoxPanel {
                Layout.fillWidth: true
                visible: isCollecting || isDetecting || collectProgress > 0

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: isDetecting ? qsTr("Detection Progress") : qsTr("Collection Progress")
                            font.bold: true
                            font.pixelSize: 13
                            color: mainWindow.textColor
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: qsTr("%1%").arg(Math.round(collectProgress * 100))
                            font.bold: true
                            font.pixelSize: 13
                            color: DTKStyle.highlightColor
                        }
                    }

                    DTKProgressBar {
                        Layout.fillWidth: true
                        value: collectProgress
                        from: 0
                        to: 1
                    }

                    Text {
                        text: currentModule || qsTr("Initializing...")
                        font.pixelSize: 12
                        color: mainWindow.mutedTextColor
                    }
                }
            }

            // Results area
            DTKBoxPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: collectResult !== null || detectResult !== null

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    DTKTabBar {
                        id: resultTabBar
                        Layout.fillWidth: true
                        model: [
                            { label: qsTr("Collection"), value: "collect" },
                            { label: qsTr("Detection"), value: "detect" }
                        ]
                    }

                    StackLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: resultTabBar.currentIndex

                        ResultView {
                            id: collectionView
                            resultData: collectResult
                        }

                        ResultView {
                            id: detectView
                            resultData: detectResult
                        }
                    }
                }
            }

            // Status bar
            Text {
                Layout.fillWidth: true
                text: isCollecting ? qsTr("Collecting information...")
                    : isDetecting ? qsTr("Detecting issues...")
                    : qsTr("%1 modules selected").arg(moduleSelector.selectedModules.length)
                color: mainWindow.mutedTextColor
                font.pixelSize: 11
            }
        }
    }

    function updateActionState() {
        // action buttons use enabled bindings driven by moduleSelector state
    }

    function startCollection() {
        var selected = moduleSelector.selectedModules
        if (selected.length === 0) {
            return
        }

        isCollecting = true
        isDetecting = false
        collectProgress = 0
        currentModule = ""

        currentTaskId = backend.collect(selected)

        if (currentTaskId === "") {
            isCollecting = false
        }
    }

    function startDetection() {
        var selected = moduleSelector.selectedModules
        if (selected.length === 0) {
            return
        }

        isDetecting = true
        isCollecting = false

        var result = backend.detect(selected)

        try {
            detectResult = JSON.parse(result)
        } catch (e) {
            console.error("Detection failed:", e)
        }
        isDetecting = false
    }

    Connections {
        target: backend

        onCollectProgress: {
            if (arguments[0] === currentTaskId) {
                collectProgress = arguments[2]
                currentModule = arguments[1]
            }
        }

        onCollectFinished: {
            if (arguments[0] === currentTaskId) {
                isCollecting = false
                isDetecting = false
                collectProgress = 1.0
                currentModule = ""

                try {
                    collectResult = JSON.parse(arguments[1])
                } catch (e) {
                    console.error("Failed to parse result:", e)
                }
            }
        }
    }
}

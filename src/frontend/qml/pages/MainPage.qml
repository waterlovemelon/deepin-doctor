import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

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

            GroupBox {
                title: qsTr("Modules")
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
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

                        onSelectionChanged: function(modules) {
                            updateActionState()
                        }
                    }
                }
            }

            // Selection summary
            Label {
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
            GroupBox {
                Layout.fillWidth: true

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
                        text: isCollecting ? qsTr("Collecting...") : qsTr("Ready")
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: qsTr("Collect")
                        enabled: !isCollecting && !isDetecting && moduleSelector.selectedModules.length > 0
                        onClicked: startCollection()
                    }

                    Button {
                        text: qsTr("Detect")
                        enabled: !isCollecting && !isDetecting && moduleSelector.selectedModules.length > 0
                        onClicked: startDetection()
                    }

                    Button {
                        text: qsTr("Export")
                        enabled: !isCollecting && !isDetecting && collectResult !== null
                        onClicked: exportRequested(collectResult)
                    }
                }
            }

            // Progress area
            GroupBox {
                Layout.fillWidth: true
                visible: isCollecting || isDetecting || collectProgress > 0

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            text: isDetecting ? qsTr("Detection Progress") : qsTr("Collection Progress")
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: qsTr("%1%").arg(Math.round(collectProgress * 100))
                            font.bold: true
                        }
                    }

                    ProgressBar {
                        Layout.fillWidth: true
                        value: collectProgress
                        from: 0
                        to: 1
                    }

                    Label {
                        text: currentModule || qsTr("Initializing...")
                        color: mainWindow.mutedTextColor
                    }
                }
            }

            // Results area
            GroupBox {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: collectResult !== null || detectResult !== null

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    TabBar {
                        id: resultTabBar
                        Layout.fillWidth: true

                        TabButton {
                            text: qsTr("Collection")
                            enabled: collectResult !== null
                        }

                        TabButton {
                            text: qsTr("Detection")
                            enabled: detectResult !== null
                        }
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
            Label {
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

        function onCollectProgress(taskId, module, progress) {
            if (taskId === currentTaskId) {
                collectProgress = progress
                currentModule = module
            }
        }

        function onCollectFinished(taskId, result) {
            if (taskId === currentTaskId) {
                isCollecting = false
                isDetecting = false
                collectProgress = 1.0
                currentModule = ""

                try {
                    collectResult = JSON.parse(result)
                } catch (e) {
                    console.error("Failed to parse result:", e)
                }
            }
        }
    }
}

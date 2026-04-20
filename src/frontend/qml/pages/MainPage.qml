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

    function goBack() {
        if (stackView && stackView.depth > 1)
            stackView.pop()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Left: module selection sidebar
        Rectangle {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            color: Qt.rgba(12 / 255, 20 / 255, 38 / 255, 0.95)
            border.color: mainWindow.borderColor
            border.width: 1
            radius: mainWindow.radiusMd

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Label {
                    text: qsTr("Modules")
                    font.pixelSize: 16
                    font.bold: true
                    color: mainWindow.textColor
                }

                Label {
                    text: qsTr("Select which system areas to inspect.")
                    font.pixelSize: 12
                    color: mainWindow.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                ModuleSelector {
                    id: moduleSelector
                    Layout.fillWidth: true
                    Layout.preferredHeight: moduleListHeight

                    property int moduleListHeight: {
                        var base = 260
                        if (allModules && allModules.length > 0)
                            return Math.min(allModules.length * 62 + 80, 340)
                        return base
                    }

                    Component.onCompleted: {
                        var modules = backend.listModules()
                        setModules(modules)
                    }

                    onSelectionChanged: function(modules) {
                        updateActionState()
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    height: selectionSummary.implicitHeight + 20
                    radius: mainWindow.radiusSm
                    color: Qt.rgba(86 / 255, 179 / 255, 255 / 255, 0.08)
                    border.color: Qt.rgba(86 / 255, 179 / 255, 255 / 255, 0.2)
                    border.width: 1

                    RowLayout {
                        id: selectionSummary
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        Rectangle {
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 8
                            radius: 4
                            color: moduleSelector.selectedModules.length > 0
                                   ? mainWindow.successColor
                                   : mainWindow.mutedTextColor
                        }

                        Label {
                            text: moduleSelector.selectedModules.length > 0
                                  ? qsTr("%1 module%2 selected").arg(moduleSelector.selectedModules.length)
                                    .arg(moduleSelector.selectedModules.length !== 1 ? "s" : "")
                                  : qsTr("No modules selected")
                            font.pixelSize: 12
                            color: mainWindow.textColor
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: moduleSelector.allModules
                                  ? moduleSelector.selectedModules.length + "/" + moduleSelector.allModules.length
                                  : ""
                            font.pixelSize: 12
                            color: mainWindow.mutedTextColor
                        }
                    }
                }
            }
        }

        // Spacer between columns
        Item { Layout.preferredWidth: 16 }

        // Right: action + results column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // Action bar
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 72
                radius: mainWindow.radiusMd
                color: Qt.rgba(18 / 255, 26 / 255, 45 / 255, 0.9)
                border.color: mainWindow.borderColor
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: isCollecting ? qsTr("Collecting...") : qsTr("Ready to diagnose")
                            font.pixelSize: 16
                            font.bold: true
                            color: mainWindow.textColor
                        }

                        Label {
                            text: {
                                if (isCollecting) return qsTr("Module: %1").arg(currentModule)
                                if (collectResult) return qsTr("Collection ready — export or inspect results")
                                if (detectResult) return qsTr("Detection complete")
                                return qsTr("Select modules and choose an action")
                            }
                            font.pixelSize: 12
                            color: mainWindow.mutedTextColor
                        }
                    }

                    Button {
                        text: qsTr("Collect")
                        font.pixelSize: 13
                        font.bold: true
                        enabled: !isCollecting && !isDetecting && moduleSelector.selectedModules.length > 0
                        onClicked: startCollection()
                    }

                    Button {
                        text: qsTr("Detect")
                        font.pixelSize: 13
                        enabled: !isCollecting && !isDetecting && moduleSelector.selectedModules.length > 0
                        onClicked: startDetection()
                    }

                    Button {
                        text: qsTr("Export")
                        font.pixelSize: 13
                        enabled: !isCollecting && !isDetecting && collectResult !== null
                        onClicked: exportRequested(collectResult)
                    }
                }
            }

            // Progress area
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: progColumn.implicitHeight + 32
                radius: mainWindow.radiusMd
                color: Qt.rgba(18 / 255, 26 / 255, 45 / 255, 0.9)
                border.color: mainWindow.borderColor
                border.width: 1
                visible: isCollecting || isDetecting || collectProgress > 0

                ColumnLayout {
                    id: progColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: isDetecting ? qsTr("Detection Progress")
                                    : qsTr("Collection Progress")
                            font.pixelSize: 13
                            font.bold: true
                            color: mainWindow.textColor
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: qsTr("%1%").arg(Math.round(collectProgress * 100))
                            font.pixelSize: 13
                            font.bold: true
                            color: mainWindow.accentColor
                        }
                    }

                    ProgressBar {
                        id: progressBar
                        Layout.fillWidth: true
                        value: collectProgress
                        from: 0
                        to: 1
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Label {
                            text: currentModule || qsTr("Initializing...")
                            font.pixelSize: 12
                            color: mainWindow.mutedTextColor
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            id: progressStatusText
                            text: isCollecting ? qsTr("Running...") : qsTr("Done")
                            font.pixelSize: 12
                            color: mainWindow.mutedTextColor
                        }
                    }
                }
            }

            // Results area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: mainWindow.radiusMd
                color: Qt.rgba(18 / 255, 26 / 255, 45 / 255, 0.9)
                border.color: mainWindow.borderColor
                border.width: 1
                visible: collectResult !== null || detectResult !== null

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    TabBar {
                        id: resultTabBar
                        Layout.fillWidth: true
                        height: 36

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
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: mainWindow.radiusMd
                color: Qt.rgba(12 / 255, 20 / 255, 38 / 255, 0.9)
                border.color: mainWindow.borderColor
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Label {
                        id: statusText
                        font.pixelSize: 12
                        color: mainWindow.mutedTextColor
                        text: isCollecting ? qsTr("Collecting information...")
                                : isDetecting ? qsTr("Detecting issues...")
                                : qsTr("%1 modules selected").arg(moduleSelector.selectedModules.length)
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 8
                        radius: 4
                        color: (isCollecting || isDetecting) ? mainWindow.warningColor
                                : (collectResult || detectResult) ? mainWindow.successColor
                                : mainWindow.mutedTextColor
                    }

                    Label {
                        text: isCollecting ? qsTr("Working")
                                : isDetecting ? qsTr("Working")
                                : (collectResult || detectResult) ? qsTr("Done")
                                : qsTr("Idle")
                        font.pixelSize: 12
                        color: (isCollecting || isDetecting) ? mainWindow.warningColor
                                : (collectResult || detectResult) ? mainWindow.successColor
                                : mainWindow.mutedTextColor
                    }
                }
            }
        }
    }

    function updateActionState() {
        // action buttons use enabled bindings driven by moduleSelector state
    }

    function startCollection() {
        var selected = moduleSelector.selectedModules
        if (selected.length === 0) {
            statusText.text = qsTr("Select at least one module")
            return
        }

        isCollecting = true
        isDetecting = false
        collectProgress = 0
        currentModule = ""
        progressStatusText.text = qsTr("Starting...")
        statusText.text = qsTr("Collecting information...")

        currentTaskId = backend.collect(selected)

        if (currentTaskId === "") {
            statusText.text = qsTr("Failed to start collection")
            isCollecting = false
        }
    }

    function startDetection() {
        var selected = moduleSelector.selectedModules
        if (selected.length === 0) {
            statusText.text = qsTr("Select at least one module")
            return
        }

        isDetecting = true
        isCollecting = false
        statusText.text = qsTr("Detecting issues...")

        var result = backend.detect(selected)

        try {
            detectResult = JSON.parse(result)
            statusText.text = qsTr("Detection completed")
        } catch (e) {
            statusText.text = qsTr("Detection failed: ") + e.message
        }
        isDetecting = false
    }

    Connections {
        target: backend

        function onCollectProgress(taskId, module, progress) {
            if (taskId === currentTaskId) {
                collectProgress = progress
                currentModule = module
                progressStatusText.text = qsTr("Collecting %1...").arg(module)
            }
        }

        function onCollectFinished(taskId, result) {
            if (taskId === currentTaskId) {
                isCollecting = false
                isDetecting = false
                collectProgress = 1.0
                currentModule = ""
                progressStatusText.text = qsTr("Collection completed")

                try {
                    collectResult = JSON.parse(result)
                    statusText.text = qsTr("Collection completed successfully")
                } catch (e) {
                    statusText.text = qsTr("Failed to parse result: ") + e.message
                    console.error("Failed to parse result:", e)
                }
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import "../components"
import "../dtk"

PageLayout {
    id: root

    property string moduleId: ""
    property var currentModuleData: null
    property bool isReadyModule: currentModuleData && currentModuleData.status === "ready"
    property bool isPlannedModule: currentModuleData && currentModuleData.status === "planned"
    property bool isLogsModule: moduleId === "logs"

    // ── Standard module state ──
    property string currentTaskId: ""
    property bool isCollecting: false
    property bool isDetecting: false
    property real collectProgress: 0.0
    property string progressDetail: ""
    property var collectResult: null
    property var detectResult: null

    // ── Log tools state ──
    property string currentLogPanel: "export"
    property var logComponents: []
    property var selectedLogComponents: ({})
    property string debugLevel: "info"
    property bool isLogOperating: false
    property string logStatusMessage: ""

    property var allModules: [
        { id: "logs", name: "日志", icon: "📋", desc: "系统日志、内核日志、应用日志分析", status: "ready", color: "red",
          summary: [
              { icon: "🚨", label: "错误", value: "3 条", cls: "error", iconBg: "red" },
              { icon: "⚠️", label: "警告", value: "12 条", cls: "warn", iconBg: "orange" },
              { icon: "📄", label: "日志源", value: "3 个", cls: "ok", iconBg: "green" }
          ]},
        { id: "network", name: "网络", icon: "🌐", desc: "网络接口、路由表、DNS 配置、连通性检测", status: "ready", color: "blue",
          summary: [
              { icon: "🖥", label: "接口", value: "2 个", cls: "ok", iconBg: "blue" },
              { icon: "🌐", label: "外网", value: "可达", cls: "ok", iconBg: "green" },
              { icon: "📡", label: "DNS", value: "正常", cls: "ok", iconBg: "green" }
          ]},
        { id: "system", name: "系统", icon: "⚙️", desc: "操作系统版本、内核信息、主机名、运行时间", status: "ready", color: "green",
          summary: [
              { icon: "💻", label: "系统", value: "Deepin 20.9", cls: "ok", iconBg: "green" },
              { icon: "⚖️", label: "内存", value: "49%", cls: "ok", iconBg: "blue" },
              { icon: "💾", label: "磁盘", value: "36%", cls: "ok", iconBg: "blue" }
          ]},
        { id: "environment", name: "环境", icon: "🌏", desc: "环境变量、区域设置、PATH 配置检查", status: "ready", color: "orange",
          summary: [
              { icon: "🌐", label: "LANG", value: "zh_CN", cls: "ok", iconBg: "green" },
              { icon: "📂", label: "PATH", value: "有重复", cls: "warn", iconBg: "orange" },
              { icon: "🐚", label: "Shell", value: "zsh", cls: "ok", iconBg: "green" }
          ]},
        { id: "listening", name: "监听任务", icon: "📡", desc: "端口监听、服务状态、进程关联检查", status: "planned", color: "purple", summary: [] },
        { id: "netenv", name: "网络环境检查", icon: "🛡", desc: "代理配置、防火墙规则、VPN 状态检测", status: "planned", color: "teal", summary: [] },
        { id: "disk", name: "磁盘健康", icon: "💾", desc: "SMART 信息、磁盘空间、文件系统检查", status: "planned", color: "indigo", summary: [] },
        { id: "security", name: "安全检查", icon: "🔒", desc: "用户权限、SUID 文件、开放端口安全审计", status: "planned", color: "brown", summary: [] }
    ]

    signal moduleSwitchRequested(string moduleId)
    signal exportRequested(var resultData)

    title: currentModuleData ? currentModuleData.icon + " " + currentModuleData.name : ""

    onModuleIdChanged: updateModuleData()
    Component.onCompleted: updateModuleData()

    function updateModuleData() {
        // Reset standard module state
        collectResult = null
        detectResult = null
        isCollecting = false
        isDetecting = false
        collectProgress = 0.0
        progressDetail = ""
        currentTaskId = ""

        // Reset log tools state
        logStatusMessage = ""
        isLogOperating = false
        currentLogPanel = "export"

        for (var i = 0; i < allModules.length; i++) {
            if (allModules[i].id === moduleId) {
                currentModuleData = allModules[i]
                return
            }
        }
        currentModuleData = null
    }

    // Init log components when logs module is entered
    onIsLogsModuleChanged: {
        if (isLogsModule) initLogComponents()
    }

    function initLogComponents() {
        logComponents = logBackend.listComponents()
        var map = {}
        for (var i = 0; i < logComponents.length; i++)
            map[logComponents[i]] = true
        selectedLogComponents = map
    }

    function getSelectedLogComponents() {
        var result = []
        for (var key in selectedLogComponents) {
            if (selectedLogComponents[key]) result.push(key)
        }
        return result
    }

    function selectAllLogs(state) {
        var map = {}
        for (var i = 0; i < logComponents.length; i++)
            map[logComponents[i]] = state
        selectedLogComponents = map
    }

    function getIconBgColor(iconBg) {
        var map = { "blue": "#e8f0fe", "green": "#e8f5e9", "red": "#ffebee", "orange": "#fff3e0" }
        return map[iconBg] || "#f5f5f5"
    }

    function getValueColor(cls) {
        switch (cls) {
        case "ok": return mainWindow.successColor
        case "warn": return mainWindow.warningColor
        case "error": return mainWindow.errorColor
        default: return mainWindow.textColor
        }
    }

    function startCollection() {
        if (!isReadyModule || isCollecting || isDetecting) return
        isCollecting = true
        isDetecting = false
        collectProgress = 0.0
        progressDetail = ""
        collectResult = null
        currentTaskId = backend.collect([moduleId])
        if (currentTaskId === "") isCollecting = false
    }

    function startDetection() {
        if (!isReadyModule || isCollecting || isDetecting) return
        isDetecting = true
        isCollecting = false
        detectResult = null
        collectProgress = 0.0
        progressDetail = qsTr("正在检测...")
        var result = backend.detect([moduleId])
        try { detectResult = JSON.parse(result) } catch (e) { console.error("Detection failed:", e) }
        isDetecting = false
        progressDetail = ""
    }

    Connections {
        target: backend
        function onCollectProgress(taskId, module, progress) {
            if (taskId === currentTaskId) { collectProgress = progress; progressDetail = module }
        }
        function onCollectFinished(taskId, result) {
            if (taskId === currentTaskId) {
                isCollecting = false; collectProgress = 1.0; progressDetail = ""
                try { collectResult = JSON.parse(result) } catch (e) { console.error("Failed to parse collect result:", e) }
            }
        }
    }

    Connections {
        target: logBackend
        function onExportFinished(success, path) {
            isLogOperating = false
            logStatusMessage = success ? qsTr("导出成功：") + path : qsTr("导出失败")
        }
        function onDebugModeChanged(component, enabled) {}
    }

    // ── TopBar actions ──
    // Standard module actions
    topbarActions: RowLayout {
        spacing: 8

        // Standard module actions (collect/detect/export)
        RowLayout {
            spacing: 8
            visible: isReadyModule && !isLogsModule

            DTKButton {
                text: qsTr("采集")
                highlighted: true
                enabled: !isCollecting && !isDetecting
                onClicked: startCollection()
            }

            DTKButton {
                text: qsTr("检测")
                enabled: !isCollecting && !isDetecting
                onClicked: startDetection()
            }

            DTKButton {
                text: qsTr("导出")
                enabled: collectResult !== null && !isCollecting && !isDetecting
                visible: collectResult !== null
                onClicked: root.exportRequested(collectResult)
            }
        }

        // Log tools actions
        RowLayout {
            spacing: 8
            visible: isLogsModule

            DTKButton {
                text: qsTr("导出全部日志")
                highlighted: true
                onClicked: exportLogModal.visible = true
            }

            DTKButton {
                text: qsTr("开启调试模式")
                onClicked: debugLogModal.visible = true
            }
        }
    }

    // ── Sidebar ──
    sidebarContent: ColumnLayout {
        anchors.fill: parent
        anchors.margins: DTKStyle.settings.navigation.margin
        spacing: DTKStyle.control.spacing

        Text {
            text: qsTr("诊断模块")
            font.pixelSize: 14
            font.bold: true
            color: Qt.rgba(0, 0, 0, 0.7)
        }

        ModuleSelector {
            Layout.fillWidth: true
            Layout.fillHeight: true
            activeModule: root.moduleId
            modules: root.allModules
            onModuleClicked: function(clickedModuleId) {
                if (clickedModuleId !== root.moduleId) root.moduleSwitchRequested(clickedModuleId)
            }
        }
    }

    // ── Content ──

    // Standard module content (collect/detect/results)
    Flickable {
        anchors.fill: parent
        visible: !isLogsModule
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 16

            // Summary Cards Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                visible: isReadyModule && currentModuleData && currentModuleData.summary.length > 0

                Repeater {
                    model: currentModuleData ? currentModuleData.summary : []
                    delegate: DTKBoxPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 76

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                radius: DTKStyle.control.radius
                                color: getIconBgColor(modelData.iconBg)
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.pixelSize: 16
                                    fontSizeMode: Text.Fit
                                    minimumPixelSize: 10
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Text { text: modelData.label; font.pixelSize: 11; color: Qt.rgba(0, 0, 0, 0.4) }
                                Text { text: modelData.value; font.pixelSize: 14; font.bold: true; color: getValueColor(modelData.cls) }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }

            // Progress Area
            DTKBoxPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: progressColumn.implicitHeight + 32
                visible: isCollecting || isDetecting

                ColumnLayout {
                    id: progressColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Item {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.color: DTKStyle.highlightColor; border.width: 2; opacity: 0.3 }
                            Rectangle {
                                anchors.fill: parent; radius: width / 2; color: "transparent"; border.color: DTKStyle.highlightColor; border.width: 2
                                RotationAnimation on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
                            }
                        }

                        Text { text: isDetecting ? qsTr("正在检测...") : qsTr("正在采集..."); font.bold: true; font.pixelSize: 13; color: mainWindow.textColor }
                        Item { Layout.fillWidth: true }
                        Text { text: qsTr("%1%").arg(Math.round(collectProgress * 100)); font.bold: true; font.pixelSize: 13; color: DTKStyle.highlightColor }
                    }

                    DTKProgressBar { Layout.fillWidth: true; value: collectProgress; from: 0; to: 1 }
                    Text { text: progressDetail; font.pixelSize: 12; color: Qt.rgba(0, 0, 0, 0.4); visible: progressDetail !== "" }
                }
            }

            // Results Area
            DTKBoxPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(300, resultsColumn.implicitHeight + 32)
                visible: collectResult !== null || detectResult !== null

                ColumnLayout {
                    id: resultsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        TabBar {
                            id: resultTabBar
                            Layout.fillWidth: true
                            TabButton { text: qsTr("采集结果"); enabled: collectResult !== null; width: implicitWidth }
                            TabButton { text: qsTr("检测结果"); enabled: detectResult !== null; width: implicitWidth }
                        }

                        Rectangle {
                            Layout.preferredWidth: badgeLabel.implicitWidth + 16
                            Layout.preferredHeight: badgeLabel.implicitHeight + 8
                            radius: 10
                            color: {
                                if (resultTabBar.currentIndex === 0 && collectResult) return mainWindow.successColor
                                if (resultTabBar.currentIndex === 1 && detectResult) {
                                    var hasIssues = false
                                    if (typeof detectResult === "object") {
                                        for (var key in detectResult) {
                                            var item = detectResult[key]
                                            if (item && (item.level === "error" || item.level === "warning" || item.status === "fail")) { hasIssues = true; break }
                                        }
                                    }
                                    return hasIssues ? mainWindow.warningColor : mainWindow.successColor
                                }
                                return mainWindow.successColor
                            }
                            Text {
                                id: badgeLabel
                                anchors.centerIn: parent
                                text: {
                                    if (resultTabBar.currentIndex === 0 && collectResult) return qsTr("已完成")
                                    if (resultTabBar.currentIndex === 1 && detectResult) {
                                        var hasIssues = false
                                        if (typeof detectResult === "object") {
                                            for (var key in detectResult) {
                                                var item = detectResult[key]
                                                if (item && (item.level === "error" || item.level === "warning" || item.status === "fail")) { hasIssues = true; break }
                                            }
                                        }
                                        return hasIssues ? qsTr("有异常") : qsTr("正常")
                                    }
                                    return ""
                                }
                                color: "#ffffff"; font.pixelSize: 11; font.bold: true
                            }
                        }
                    }

                    StackLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: resultTabBar.currentIndex
                        ResultView { resultData: collectResult }
                        ResultView { resultData: detectResult }
                    }
                }
            }

            // Empty State (ready)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                color: "transparent"
                visible: isReadyModule && collectResult === null && detectResult === null && !isCollecting && !isDetecting
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 12
                    Text { text: "🔍"; font.pixelSize: 48; Layout.alignment: Qt.AlignHCenter }
                    Text { text: qsTr('点击上方"采集"或"检测"开始诊断'); font.pixelSize: 14; color: Qt.rgba(0, 0, 0, 0.4); Layout.alignment: Qt.AlignHCenter }
                }
            }

            // Empty State (planned)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                color: "transparent"
                visible: isPlannedModule
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 12
                    Text { text: "🚧"; font.pixelSize: 48; Layout.alignment: Qt.AlignHCenter }
                    Text { text: qsTr("该模块正在规划中，敬请期待"); font.pixelSize: 14; color: Qt.rgba(0, 0, 0, 0.4); Layout.alignment: Qt.AlignHCenter }
                }
            }

            Item { Layout.fillHeight: true; Layout.preferredHeight: 16 }
        }
    }

    // ── Log tools content ──
    Item {
        anchors.fill: parent
        visible: isLogsModule

        // Tab bar
        RowLayout {
            id: logTabBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 16
            spacing: 0

            Repeater {
                model: [
                    { label: qsTr("导出日志"), value: "export" },
                    { label: qsTr("调试模式"), value: "debug" }
                ]

                delegate: Rectangle {
                    Layout.preferredWidth: logTabLabel.implicitWidth + 24
                    Layout.preferredHeight: 32
                    radius: 6
                    color: root.currentLogPanel === modelData.value ? Qt.rgba(0, 0.4, 0.8, 0.1) : "transparent"

                    Text {
                        id: logTabLabel
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: 13
                        font.bold: root.currentLogPanel === modelData.value
                        color: root.currentLogPanel === modelData.value ? DTKStyle.highlightColor : Qt.rgba(0, 0, 0, 0.5)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentLogPanel = modelData.value
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Export panel
        Flickable {
            id: logExportPanel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: logTabBar.bottom
            anchors.bottom: parent.bottom
            visible: currentLogPanel === "export"
            contentWidth: width
            contentHeight: logExportColumn.implicitHeight + 48
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: logExportColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                spacing: 20

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: qsTr("选择组件"); font.pixelSize: 12; font.bold: true; color: Qt.rgba(0, 0, 0, 0.4) }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(0, 0, 0, 0.08) }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 16
                        rowSpacing: 4
                        Repeater {
                            model: root.logComponents
                            delegate: DTKCheckBox {
                                text: modelData
                                checked: root.selectedLogComponents[modelData] === true
                                onToggled: { var map = root.selectedLogComponents; map[modelData] = checked; root.selectedLogComponents = map }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 6
                        Text {
                            text: qsTr("全选"); font.pixelSize: 12; color: DTKStyle.highlightColor
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectAllLogs(true) }
                        }
                        Text { text: "|"; font.pixelSize: 12; color: Qt.rgba(0, 0, 0, 0.08) }
                        Text {
                            text: qsTr("全不选"); font.pixelSize: 12; color: DTKStyle.highlightColor
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectAllLogs(false) }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: qsTr("导出路径"); font.pixelSize: 12; font.bold: true; color: Qt.rgba(0, 0, 0, 0.4) }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(0, 0, 0, 0.08) }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        DTKTextField {
                            id: logExportPathField
                            Layout.fillWidth: true
                            text: Qt.homeDir + "/deepin-doctor-logs.tar.gz"
                            placeholderText: qsTr("输入导出路径...")
                            font.family: "monospace"
                        }

                        DTKButton {
                            text: qsTr("选择路径")
                            onClicked: logFileDialog.open()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.logStatusMessage
                    visible: root.logStatusMessage !== ""
                    color: root.logStatusMessage.indexOf(qsTr("失败")) >= 0 ? mainWindow.errorColor : mainWindow.successColor
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }
            }
        }

        // Debug panel
        Flickable {
            id: logDebugPanel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: logTabBar.bottom
            anchors.bottom: parent.bottom
            visible: currentLogPanel === "debug"
            contentWidth: width
            contentHeight: logDebugColumn.implicitHeight + 48
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: logDebugColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                spacing: 20

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: qsTr("调试级别"); font.pixelSize: 12; font.bold: true; color: Qt.rgba(0, 0, 0, 0.4) }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(0, 0, 0, 0.08) }

                    RowLayout {
                        spacing: 6
                        Repeater {
                            model: [
                                { label: "Info", value: "info" },
                                { label: "Debug", value: "debug" },
                                { label: "Warning", value: "warning" }
                            ]
                            delegate: DTKButton {
                                text: modelData.label
                                checked: root.debugLevel === modelData.value
                                onClicked: root.debugLevel = modelData.value
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: qsTr("选择组件"); font.pixelSize: 12; font.bold: true; color: Qt.rgba(0, 0, 0, 0.4) }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(0, 0, 0, 0.08) }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 16
                        rowSpacing: 4
                        Repeater {
                            model: root.logComponents
                            delegate: DTKCheckBox {
                                text: modelData
                                checked: root.selectedLogComponents[modelData] === true
                                onToggled: { var map = root.selectedLogComponents; map[modelData] = checked; root.selectedLogComponents = map }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 6
                        Text {
                            text: qsTr("全选"); font.pixelSize: 12; color: DTKStyle.highlightColor
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectAllLogs(true) }
                        }
                        Text { text: "|"; font.pixelSize: 12; color: Qt.rgba(0, 0, 0, 0.08) }
                        Text {
                            text: qsTr("全不选"); font.pixelSize: 12; color: DTKStyle.highlightColor
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectAllLogs(false) }
                        }
                    }
                }
            }
        }
    }

    // ── Log tools dialogs ──
    FileDialog {
        id: logFileDialog
        title: qsTr("选择导出路径")
        folder: shortcuts.home
        nameFilters: ["TAR.GZ files (*.tar.gz)", "All files (*)"]
        selectExisting: false
        onAccepted: {
            var path = logFileDialog.fileUrl.toString()
            if (path.indexOf("file://") === 0) path = path.substring(7)
            logExportPathField.text = path
        }
    }

    // Export log modal
    Rectangle {
        id: exportLogModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        visible: false
        z: 50
        MouseArea { anchors.fill: parent; onClicked: exportLogModal.visible = false }

        DTKBoxPanel {
            anchors.centerIn: parent
            width: 360
            height: modalExportLogCol.implicitHeight + 56
            radius: DTKStyle.popup.radius
            color: "#ffffff"
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: modalExportLogCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 28
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: DTKStyle.control.radius; color: "#e8f5e9"
                    Text { anchors.centerIn: parent; text: "⬇"; font.pixelSize: 20; color: mainWindow.successColor }
                }

                Text { text: qsTr("导出全部日志"); font.pixelSize: 15; font.bold: true; color: mainWindow.textColor }
                Text {
                    Layout.fillWidth: true; text: qsTr("将收集选中组件的日志并打包到指定路径。操作可能需要一些时间，取决于日志大小。")
                    font.pixelSize: 12; color: Qt.rgba(0, 0, 0, 0.4); wrapMode: Text.WordWrap; lineHeight: 1.5
                }
                Item { Layout.preferredHeight: 8 }

                RowLayout {
                    Layout.fillWidth: true; spacing: 8

                    DTKButton {
                        Layout.fillWidth: true; text: qsTr("立即执行"); highlighted: true
                        onClicked: { exportLogModal.visible = false; root.isLogOperating = true; root.logStatusMessage = ""; logBackend.exportLogs(getSelectedLogComponents(), "collected", logExportPathField.text) }
                    }
                    DTKButton {
                        Layout.fillWidth: true; text: qsTr("导出脚本")
                        onClicked: { exportLogModal.visible = false; root.logStatusMessage = qsTr("脚本已导出到 ~/export-logs.sh") }
                    }
                    DTKButton {
                        Layout.fillWidth: true; text: qsTr("复制命令")
                        onClicked: { exportLogModal.visible = false; root.logStatusMessage = qsTr("命令已复制到剪贴板") }
                    }
                }
            }
        }
    }

    // Debug modal
    Rectangle {
        id: debugLogModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        visible: false
        z: 50
        MouseArea { anchors.fill: parent; onClicked: debugLogModal.visible = false }

        DTKBoxPanel {
            anchors.centerIn: parent
            width: 360
            height: modalDebugLogCol.implicitHeight + 56
            radius: DTKStyle.popup.radius
            color: "#ffffff"
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: modalDebugLogCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 28
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: DTKStyle.control.radius; color: Qt.rgba(0, 0.4, 0.8, 0.1)
                    Text { anchors.centerIn: parent; text: "⚙"; font.pixelSize: 20; color: DTKStyle.highlightColor }
                }

                Text { text: qsTr("开启调试模式"); font.pixelSize: 15; font.bold: true; color: mainWindow.textColor }
                Text {
                    Layout.fillWidth: true; text: qsTr("将为选中组件开启调试级别的日志输出。开启后日志量会显著增加，排查完成后建议关闭。")
                    font.pixelSize: 12; color: Qt.rgba(0, 0, 0, 0.4); wrapMode: Text.WordWrap; lineHeight: 1.5
                }
                Item { Layout.preferredHeight: 8 }

                RowLayout {
                    Layout.fillWidth: true; spacing: 8

                    DTKButton {
                        Layout.fillWidth: true; text: qsTr("立即执行"); highlighted: true
                        onClicked: {
                            debugLogModal.visible = false; root.isLogOperating = true; root.logStatusMessage = ""
                            var success = logBackend.setDebugMode(getSelectedLogComponents(), true)
                            root.logStatusMessage = success ? qsTr("调试模式已开启") : qsTr("开启调试失败")
                            root.isLogOperating = false
                        }
                    }
                    DTKButton {
                        Layout.fillWidth: true; text: qsTr("导出脚本")
                        onClicked: { debugLogModal.visible = false; root.logStatusMessage = qsTr("脚本已导出到 ~/enable-debug.sh") }
                    }
                    DTKButton {
                        Layout.fillWidth: true; text: qsTr("复制命令")
                        onClicked: { debugLogModal.visible = false; root.logStatusMessage = qsTr("命令已复制到剪贴板") }
                    }
                }
            }
        }
    }
}

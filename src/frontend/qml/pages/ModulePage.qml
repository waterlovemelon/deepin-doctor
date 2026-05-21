import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
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
    property bool isKeyringModule: moduleId === "keyring"

    // ── Standard module state ──
    property string currentTaskId: ""
    property bool isCollecting: false
    property bool isDetecting: false
    property real collectProgress: 0.0
    property string progressDetail: ""
    property var collectResult: null
    property var detectResult: null

    // ── Log tools state ──
    property var logComponents: []
    property var selectedLogComponents: ({})
    property string debugLevel: "info"
    property bool isLogOperating: false
    property string logStatusMessage: ""

    // ── Keyring state ──
    property var keyringUserList: []
    property string keyringSelectedUser: ""
    property bool keyringCheckAllUsers: false
    property bool isKeyringRunning: false
    property string keyringRawOutput: ""
    property var keyringResults: []
    property string keyringMode: "check"

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
        { id: "keyring", name: "密钥环", icon: "🔑", desc: "白盒密钥环文件检测与修复", status: "ready", color: "cyan", summary: [] },
        { id: "listening", name: "监听任务", icon: "📡", desc: "端口监听、服务状态、进程关联检查", status: "planned", color: "purple", summary: [] },
        { id: "netenv", name: "网络环境检查", icon: "🛡", desc: "代理配置、防火墙规则、VPN 状态检测", status: "planned", color: "teal", summary: [] },
        { id: "disk", name: "磁盘健康", icon: "💾", desc: "SMART 信息、磁盘空间、文件系统检查", status: "planned", color: "indigo", summary: [] },
        { id: "security", name: "安全检查", icon: "🔒", desc: "用户权限、SUID 文件、开放端口安全审计", status: "planned", color: "brown", summary: [] }
    ]

    signal moduleSwitchRequested(string moduleId)
    signal exportRequested(var resultData)

    title: ""

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
        logTabBar.currentIndex = 0

        // Reset keyring state
        keyringRawOutput = ""
        keyringResults = []
        isKeyringRunning = false
        keyringMode = "check"

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

    // Init keyring users when keyring module is entered
    onIsKeyringModuleChanged: {
        if (isKeyringModule) {
            keyringUserList = processHelper.availableUsers()
            if (keyringUserList.length > 0) keyringSelectedUser = keyringUserList[0]
        }
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

    // ── Keyring helpers ──
    function keyringStatusLabel(s) {
        switch (s) {
        case "ok":      return qsTr("正常")
        case "bad":     return qsTr("损坏")
        case "missing": return qsTr("缺失")
        case "error":   return qsTr("错误")
        default:        return s || qsTr("未知")
        }
    }

    function keyringStatusColor(s) {
        switch (s) {
        case "ok":      return mainWindow.successColor
        case "bad":     return mainWindow.errorColor
        case "missing": return mainWindow.warningColor
        case "error":   return mainWindow.errorColor
        default:        return mainWindow.mutedTextColor
        }
    }

    function keyringStatusIcon(s) {
        switch (s) {
        case "ok":      return "✓"
        case "bad":     return "✗"
        case "missing": return "—"
        case "error":   return "!"
        default:        return "?"
        }
    }

    function parseKeyringOutput(output) {
        var lines = output.split("\n")
        var parsed = []
        var current = null

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].replace(/^\[wb-keyring-fix\]\s*/, "")

            var m = line.match(/^(\S+):\s*whitebox=(\S+),\s*default=(\S+)/)
            if (m) {
                if (current) parsed.push(current)
                current = { user: m[1], wbStatus: m[2], defaultStatus: m[3], detail: "" }
                continue
            }

            if (current && line.indexOf(current.user + ":") === 0) {
                var detailText = line.substring(current.user.length + 1).trim()
                if (detailText && detailText.indexOf("whitebox=") < 0) {
                    current.detail += (current.detail ? "\n" : "") + detailText
                }
            }
        }
        if (current) parsed.push(current)
        return parsed
    }

    function runKeyringCheck() { runKeyring(false) }
    function runKeyringFix() { runKeyring(true) }

    function runKeyring(fixMode) {
        if (isKeyringRunning) return
        isKeyringRunning = true
        keyringRawOutput = ""
        keyringResults = []
        keyringMode = fixMode ? "fix" : "check"

        var script = processHelper.findTool("wb-keyring-fix.sh")
        if (!script) {
            keyringRawOutput = qsTr("错误：找不到 wb-keyring-fix.sh 脚本，请确认已安装 deepin-doctor")
            isKeyringRunning = false
            return
        }

        var args = []
        if (fixMode) args.push("--fix")
        if (keyringCheckAllUsers) {
            args.push("--all-users")
        } else if (keyringSelectedUser !== "") {
            args.push("--user=" + keyringSelectedUser)
        }

        var output = processHelper.run(script, args, 60000)
        keyringRawOutput = output
        keyringResults = parseKeyringOutput(output)
        isKeyringRunning = false
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
        onCollectProgress: {
            if (arguments[0] === currentTaskId) { collectProgress = arguments[2]; progressDetail = arguments[1] }
        }
        onCollectFinished: {
            if (arguments[0] === currentTaskId) {
                isCollecting = false; collectProgress = 1.0; progressDetail = ""
                try { collectResult = JSON.parse(arguments[1]) } catch (e) { console.error("Failed to parse collect result:", e) }
            }
        }
    }

    Connections {
        target: logBackend
        onExportFinished: {
            isLogOperating = false
            logStatusMessage = arguments[0] ? qsTr("导出成功：") + arguments[1] : qsTr("导出失败")
        }
        onDebugModeChanged: {}
    }

    // ── TopBar actions ──
    // Standard module actions
    topbarActions: RowLayout {
        spacing: 8

        // Standard module actions (collect/detect/export)
        RowLayout {
            spacing: 8
            visible: isReadyModule && !isLogsModule && !isKeyringModule

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

        // Keyring actions
        RowLayout {
            spacing: 8
            visible: isKeyringModule

            DTKButton {
                text: qsTr("检测")
                highlighted: true
                enabled: !isKeyringRunning
                onClicked: root.runKeyringCheck()
            }

            DTKButton {
                text: qsTr("修复")
                enabled: !isKeyringRunning
                onClicked: root.runKeyringFix()
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
            onModuleClicked: {
                if (arguments[0] !== root.moduleId) root.moduleSwitchRequested(arguments[0])
            }
        }
    }

    // ── Content ──

    // Standard module content (collect/detect/results)
    Flickable {
        anchors.fill: parent
        visible: !isLogsModule && !isKeyringModule
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

                        DTKTabBar {
                            id: resultTabBar
                            Layout.fillWidth: true
                            model: [
                                { label: qsTr("采集结果"), value: "collect" },
                                { label: qsTr("检测结果"), value: "detect" }
                            ]
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
        DTKTabBar {
            id: logTabBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 16
            model: [
                { label: qsTr("导出日志"), value: "export" },
                { label: qsTr("调试模式"), value: "debug" }
            ]
        }

        // Export panel
        Flickable {
            id: logExportPanel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: logTabBar.bottom
            anchors.bottom: parent.bottom
            visible: logTabBar.currentValue === "export"
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
            visible: logTabBar.currentValue === "debug"
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

    // ── Keyring content ──
    Flickable {
        anchors.fill: parent
        visible: isKeyringModule
        contentWidth: width
        contentHeight: keyringContentColumn.implicitHeight + 48
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: keyringContentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 16

            // User Selection
            DTKBoxPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: keyringUserColumn.implicitHeight + 32

                ColumnLayout {
                    id: keyringUserColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: qsTr("选择用户")
                        font.pixelSize: 13
                        font.bold: true
                        color: mainWindow.textColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        DTKCheckBox {
                            text: qsTr("所有用户")
                            checked: root.keyringCheckAllUsers
                            onToggled: root.keyringCheckAllUsers = checked
                        }

                        Item { Layout.fillWidth: true }

                        DTKComboBox {
                            Layout.preferredWidth: 200
                            model: root.keyringUserList
                            currentIndex: root.keyringUserList.indexOf(root.keyringSelectedUser)
                            enabled: !root.keyringCheckAllUsers
                            onCurrentTextChanged: {
                                if (currentIndex >= 0) root.keyringSelectedUser = currentText
                            }
                        }
                    }
                }
            }

            // Running indicator
            DTKBoxPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: keyringRunColumn.implicitHeight + 32
                visible: isKeyringRunning

                ColumnLayout {
                    id: keyringRunColumn
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

                        Text {
                            text: root.keyringMode === "fix" ? qsTr("正在修复密钥环...") : qsTr("正在检测密钥环...")
                            font.bold: true
                            font.pixelSize: 13
                            color: mainWindow.textColor
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // Results
            DTKBoxPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(200, keyringResultsColumn.implicitHeight + 32)
                visible: keyringResults.length > 0

                ColumnLayout {
                    id: keyringResultsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: root.keyringMode === "fix" ? qsTr("修复结果") : qsTr("检测结果")
                            font.pixelSize: 14
                            font.bold: true
                            color: mainWindow.textColor
                        }

                        Rectangle {
                            Layout.preferredWidth: keyringCountLabel.implicitWidth + 16
                            Layout.preferredHeight: keyringCountLabel.implicitHeight + 8
                            radius: 10
                            color: {
                                var hasIssue = false
                                for (var i = 0; i < keyringResults.length; i++) {
                                    if (keyringResults[i].wbStatus !== "ok") { hasIssue = true; break }
                                }
                                return hasIssue ? mainWindow.warningColor : mainWindow.successColor
                            }
                            Text {
                                id: keyringCountLabel
                                anchors.centerIn: parent
                                text: keyringResults.length + qsTr(" 个用户")
                                color: "#ffffff"
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Table header
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        color: Qt.rgba(0, 0, 0, 0.03)
                        radius: 4

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text { text: qsTr("用户"); font.pixelSize: 12; font.bold: true; color: Qt.rgba(0, 0, 0, 0.5); Layout.preferredWidth: 120 }
                            Text { text: qsTr("白盒密钥环"); font.pixelSize: 12; font.bold: true; color: Qt.rgba(0, 0, 0, 0.5); Layout.preferredWidth: 100 }
                            Text { text: qsTr("默认密钥环"); font.pixelSize: 12; font.bold: true; color: Qt.rgba(0, 0, 0, 0.5); Layout.preferredWidth: 100 }
                            Text { text: qsTr("详细信息"); font.pixelSize: 12; font.bold: true; color: Qt.rgba(0, 0, 0, 0.5); Layout.fillWidth: true }
                        }
                    }

                    // Table rows
                    Repeater {
                        model: root.keyringResults

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: keyringRowContent.implicitHeight + 16
                            color: index % 2 === 0 ? "transparent" : Qt.rgba(0, 0, 0, 0.02)

                            RowLayout {
                                id: keyringRowContent
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text {
                                    text: modelData.user
                                    font.pixelSize: 12
                                    font.family: "monospace"
                                    color: mainWindow.textColor
                                    Layout.preferredWidth: 120
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    Layout.preferredWidth: 100
                                    spacing: 4

                                    Rectangle {
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        radius: 10
                                        color: Qt.rgba(
                                            root.keyringStatusColor(modelData.wbStatus).r,
                                            root.keyringStatusColor(modelData.wbStatus).g,
                                            root.keyringStatusColor(modelData.wbStatus).b, 0.12)

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.keyringStatusIcon(modelData.wbStatus)
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.keyringStatusColor(modelData.wbStatus)
                                        }
                                    }

                                    Text {
                                        text: root.keyringStatusLabel(modelData.wbStatus)
                                        font.pixelSize: 12
                                        color: root.keyringStatusColor(modelData.wbStatus)
                                    }
                                }

                                RowLayout {
                                    Layout.preferredWidth: 100
                                    spacing: 4

                                    Rectangle {
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        radius: 10
                                        color: Qt.rgba(
                                            root.keyringStatusColor(modelData.defaultStatus).r,
                                            root.keyringStatusColor(modelData.defaultStatus).g,
                                            root.keyringStatusColor(modelData.defaultStatus).b, 0.12)

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.keyringStatusIcon(modelData.defaultStatus)
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.keyringStatusColor(modelData.defaultStatus)
                                        }
                                    }

                                    Text {
                                        text: root.keyringStatusLabel(modelData.defaultStatus)
                                        font.pixelSize: 12
                                        color: root.keyringStatusColor(modelData.defaultStatus)
                                    }
                                }

                                Text {
                                    text: modelData.detail || "—"
                                    font.pixelSize: 11
                                    color: Qt.rgba(0, 0, 0, 0.4)
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                }
                            }
                        }
                    }
                }
            }

            // Raw output
            DTKBoxPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: keyringRawColumn.implicitHeight + 32
                visible: keyringRawOutput !== ""

                ColumnLayout {
                    id: keyringRawColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: qsTr("原始输出")
                            font.pixelSize: 13
                            font.bold: true
                            color: mainWindow.textColor
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: qsTr("复制")
                            font.pixelSize: 12
                            color: DTKStyle.highlightColor
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    keyringClipboardInput.text = root.keyringRawOutput
                                    keyringClipboardInput.selectAll()
                                    keyringClipboardInput.copy()
                                    keyringCopyToast.visible = true
                                    keyringCopyToastTimer.restart()
                                }
                            }
                        }

                        Text {
                            id: keyringCopyToast
                            text: qsTr("已复制")
                            font.pixelSize: 11
                            color: mainWindow.successColor
                            visible: false
                            Timer { id: keyringCopyToastTimer; interval: 1500; onTriggered: keyringCopyToast.visible = false }
                        }
                    }

                    TextInput {
                        id: keyringClipboardInput
                        visible: false
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(300, keyringRawText.implicitHeight + 16)
                        color: Qt.rgba(0, 0, 0, 0.03)
                        radius: 4

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 8
                            contentWidth: width
                            contentHeight: keyringRawText.implicitHeight
                            clip: true

                            Text {
                                id: keyringRawText
                                width: parent.width
                                text: root.keyringRawOutput
                                font.pixelSize: 11
                                font.family: "monospace"
                                color: Qt.rgba(0, 0, 0, 0.6)
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            // Empty state
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                color: "transparent"
                visible: keyringResults.length === 0 && !isKeyringRunning && keyringRawOutput === ""

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: "🔑"
                        font.pixelSize: 48
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: qsTr('点击上方"检测"开始检查密钥环状态')
                        font.pixelSize: 14
                        color: Qt.rgba(0, 0, 0, 0.4)
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: qsTr("支持单用户检测或批量扫描所有用户")
                        font.pixelSize: 12
                        color: Qt.rgba(0, 0, 0, 0.25)
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Item { Layout.fillHeight: true; Layout.preferredHeight: 16 }
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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: root

    // Set externally to display a specific module
    property string moduleId: ""

    // Internal state
    property var currentModuleData: null
    property bool isReadyModule: currentModuleData && currentModuleData.status === "ready"
    property bool isPlannedModule: currentModuleData && currentModuleData.status === "planned"

    property string currentTaskId: ""
    property bool isCollecting: false
    property bool isDetecting: false
    property real collectProgress: 0.0
    property string progressDetail: ""
    property var collectResult: null
    property var detectResult: null

    // All modules for sidebar
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

    signal backRequested()
    signal moduleSwitchRequested(string moduleId)
    signal exportRequested(var resultData)

    onModuleIdChanged: updateModuleData()

    Component.onCompleted: updateModuleData()

    function updateModuleData() {
        collectResult = null
        detectResult = null
        isCollecting = false
        isDetecting = false
        collectProgress = 0.0
        progressDetail = ""
        currentTaskId = ""

        for (var i = 0; i < allModules.length; i++) {
            if (allModules[i].id === moduleId) {
                currentModuleData = allModules[i]
                return
            }
        }
        currentModuleData = null
    }

    function getIconBgColor(iconBg) {
        switch (iconBg) {
        case "blue": return "#e8f0fe"
        case "green": return "#e8f5e9"
        case "red": return "#ffebee"
        case "orange": return "#fff3e0"
        default: return mainWindow.elevatedSurfaceColor
        }
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

        if (currentTaskId === "") {
            isCollecting = false
        }
    }

    function startDetection() {
        if (!isReadyModule || isCollecting || isDetecting) return

        isDetecting = true
        isCollecting = false
        detectResult = null
        collectProgress = 0.0
        progressDetail = qsTr("正在检测...")

        var result = backend.detect([moduleId])

        try {
            detectResult = JSON.parse(result)
        } catch (e) {
            console.error("Detection failed:", e)
        }
        isDetecting = false
        progressDetail = ""
    }

    Connections {
        target: backend

        function onCollectProgress(taskId, module, progress) {
            if (taskId === currentTaskId) {
                collectProgress = progress
                progressDetail = module
            }
        }

        function onCollectFinished(taskId, result) {
            if (taskId === currentTaskId) {
                isCollecting = false
                collectProgress = 1.0
                progressDetail = ""

                try {
                    collectResult = JSON.parse(result)
                } catch (e) {
                    console.error("Failed to parse collect result:", e)
                }
            }
        }
    }

    // Layout: sidebar + content
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Left sidebar
        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: mainWindow.surfaceColor
            border.color: mainWindow.borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Label {
                    text: qsTr("诊断模块")
                    font.bold: true
                    font.pixelSize: 13
                    color: mainWindow.textColor
                }

                ModuleSelector {
                    id: sidebar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    activeModule: root.moduleId
                    modules: root.allModules

                    onModuleClicked: function(clickedModuleId) {
                        if (clickedModuleId !== root.moduleId) {
                            root.moduleSwitchRequested(clickedModuleId)
                        }
                    }
                }
            }
        }

        // Right content area
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: root.width - 200
                spacing: 16

                // === Header Area ===
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: mainWindow.backgroundColor
                    border.color: mainWindow.borderColor
                    border.width: 1
                    radius: 8

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        // Back button
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 6
                            color: backMouseArea.containsMouse ? mainWindow.elevatedSurfaceColor : "transparent"

                            Label {
                                anchors.centerIn: parent
                                text: "←"
                                font.pixelSize: 16
                                color: mainWindow.mutedTextColor
                            }

                            MouseArea {
                                id: backMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.backRequested()
                            }
                        }

                        // Module icon
                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            radius: 10
                            color: mainWindow.elevatedSurfaceColor

                            Label {
                                anchors.centerIn: parent
                                text: currentModuleData ? currentModuleData.icon : ""
                                font.pixelSize: 24
                            }
                        }

                        // Module name + description
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: currentModuleData ? currentModuleData.name : ""
                                font.pixelSize: 16
                                font.bold: true
                                color: mainWindow.textColor
                            }

                            Label {
                                text: currentModuleData ? currentModuleData.desc : ""
                                font.pixelSize: 12
                                color: "#888888"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Action buttons
                        RowLayout {
                            spacing: 8
                            visible: isReadyModule

                            Button {
                                text: qsTr("采集")
                                enabled: !isCollecting && !isDetecting
                                onClicked: startCollection()

                                background: Rectangle {
                                    implicitWidth: 72
                                    implicitHeight: 32
                                    radius: 6
                                    color: parent.enabled ? (parent.down ? "#0055aa" : mainWindow.accentColor) : mainWindow.elevatedSurfaceColor
                                }

                                contentItem: Label {
                                    text: parent.text
                                    color: parent.enabled ? "#ffffff" : mainWindow.mutedTextColor
                                    font.pixelSize: 13
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Button {
                                text: qsTr("检测")
                                enabled: !isCollecting && !isDetecting
                                onClicked: startDetection()

                                background: Rectangle {
                                    implicitWidth: 72
                                    implicitHeight: 32
                                    radius: 6
                                    color: parent.enabled ? (parent.down ? mainWindow.elevatedSurfaceColor : mainWindow.backgroundColor) : mainWindow.elevatedSurfaceColor
                                    border.color: parent.enabled ? mainWindow.accentColor : mainWindow.borderColor
                                    border.width: 1
                                }

                                contentItem: Label {
                                    text: parent.text
                                    color: parent.enabled ? mainWindow.accentColor : mainWindow.mutedTextColor
                                    font.pixelSize: 13
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Button {
                                text: qsTr("导出")
                                enabled: collectResult !== null && !isCollecting && !isDetecting
                                visible: collectResult !== null
                                onClicked: root.exportRequested(collectResult)

                                background: Rectangle {
                                    implicitWidth: 72
                                    implicitHeight: 32
                                    radius: 6
                                    color: parent.enabled ? (parent.down ? mainWindow.elevatedSurfaceColor : mainWindow.backgroundColor) : mainWindow.elevatedSurfaceColor
                                    border.color: parent.enabled ? mainWindow.borderColor : mainWindow.borderColor
                                    border.width: 1
                                }

                                contentItem: Label {
                                    text: parent.text
                                    color: parent.enabled ? mainWindow.textColor : mainWindow.mutedTextColor
                                    font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }

                // === Summary Cards Row ===
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 12
                    visible: isReadyModule && currentModuleData && currentModuleData.summary.length > 0

                    Repeater {
                        model: currentModuleData ? currentModuleData.summary : []

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 76
                            color: mainWindow.backgroundColor
                            border.color: "#e0e0e0"
                            border.width: 1
                            radius: 6

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                // Icon box
                                Rectangle {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    radius: 6
                                    color: getIconBgColor(modelData.iconBg)

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        font.pixelSize: 16
                                    }
                                }

                                // Label + Value
                                ColumnLayout {
                                    spacing: 2

                                    Label {
                                        text: modelData.label
                                        font.pixelSize: 11
                                        color: "#888888"
                                    }

                                    Label {
                                        text: modelData.value
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: getValueColor(modelData.cls)
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }

                // === Progress Area ===
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: progressColumn.implicitHeight + 32
                    color: mainWindow.backgroundColor
                    border.color: mainWindow.borderColor
                    border.width: 1
                    radius: 8
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

                            // Spinner
                            Item {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20

                                Rectangle {
                                    id: spinner
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: "transparent"
                                    border.color: mainWindow.accentColor
                                    border.width: 2
                                    opacity: 0.3
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: "transparent"
                                    border.color: mainWindow.accentColor
                                    border.width: 2

                                    RotationAnimation on rotation {
                                        from: 0
                                        to: 360
                                        duration: 1000
                                        loops: Animation.Infinite
                                    }
                                }
                            }

                            Label {
                                text: isDetecting ? qsTr("正在检测...") : qsTr("正在采集...")
                                font.bold: true
                                font.pixelSize: 13
                                color: mainWindow.textColor
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: qsTr("%1%").arg(Math.round(collectProgress * 100))
                                font.bold: true
                                font.pixelSize: 13
                                color: mainWindow.accentColor
                            }
                        }

                        ProgressBar {
                            Layout.fillWidth: true
                            value: collectProgress
                            from: 0
                            to: 1
                        }

                        Label {
                            text: progressDetail
                            font.pixelSize: 12
                            color: mainWindow.mutedTextColor
                            visible: progressDetail !== ""
                        }
                    }
                }

                // === Results Area ===
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(300, resultsColumn.implicitHeight + 32)
                    color: mainWindow.backgroundColor
                    border.color: mainWindow.borderColor
                    border.width: 1
                    radius: 8
                    visible: collectResult !== null || detectResult !== null

                    ColumnLayout {
                        id: resultsColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 12

                        // Tab bar + badge
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            TabBar {
                                id: resultTabBar
                                Layout.fillWidth: true

                                TabButton {
                                    text: qsTr("采集结果")
                                    enabled: collectResult !== null
                                    width: implicitWidth
                                }

                                TabButton {
                                    text: qsTr("检测结果")
                                    enabled: detectResult !== null
                                    width: implicitWidth
                                }
                            }

                            // Status badge
                            Rectangle {
                                Layout.preferredWidth: badgeLabel.implicitWidth + 16
                                Layout.preferredHeight: badgeLabel.implicitHeight + 8
                                radius: 10
                                color: {
                                    if (resultTabBar.currentIndex === 0 && collectResult) {
                                        return mainWindow.successColor
                                    }
                                    if (resultTabBar.currentIndex === 1 && detectResult) {
                                        // Check if there are any issues in detect result
                                        var hasIssues = false
                                        if (typeof detectResult === "object") {
                                            for (var key in detectResult) {
                                                var item = detectResult[key]
                                                if (item && (item.level === "error" || item.level === "warning" || item.status === "fail")) {
                                                    hasIssues = true
                                                    break
                                                }
                                            }
                                        }
                                        return hasIssues ? mainWindow.warningColor : mainWindow.successColor
                                    }
                                    return mainWindow.successColor
                                }

                                Label {
                                    id: badgeLabel
                                    anchors.centerIn: parent
                                    text: {
                                        if (resultTabBar.currentIndex === 0 && collectResult) {
                                            return qsTr("已完成")
                                        }
                                        if (resultTabBar.currentIndex === 1 && detectResult) {
                                            var hasIssues = false
                                            if (typeof detectResult === "object") {
                                                for (var key in detectResult) {
                                                    var item = detectResult[key]
                                                    if (item && (item.level === "error" || item.level === "warning" || item.status === "fail")) {
                                                        hasIssues = true
                                                        break
                                                    }
                                                }
                                            }
                                            return hasIssues ? qsTr("有异常") : qsTr("正常")
                                        }
                                        return ""
                                    }
                                    color: "#ffffff"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }

                        // Result content
                        StackLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            currentIndex: resultTabBar.currentIndex

                            ResultView {
                                resultData: collectResult
                            }

                            ResultView {
                                resultData: detectResult
                            }
                        }
                    }
                }

                // === Empty State (ready modules) ===
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    color: "transparent"
                    visible: isReadyModule && collectResult === null && detectResult === null && !isCollecting && !isDetecting

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Label {
                            text: "🔍"
                            font.pixelSize: 48
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: qsTr('点击上方"采集"或"检测"开始诊断')
                            font.pixelSize: 14
                            color: mainWindow.mutedTextColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // === Empty State (planned modules) ===
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    color: "transparent"
                    visible: isPlannedModule

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Label {
                            text: "🚧"
                            font.pixelSize: 48
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: qsTr("该模块正在规划中，敬请期待")
                            font.pixelSize: 14
                            color: mainWindow.mutedTextColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Bottom spacer
                Item {
                    Layout.fillHeight: true
                    Layout.preferredHeight: 16
                }
            }
        }
    }
}

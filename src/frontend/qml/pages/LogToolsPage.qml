import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import "../components"
import "../dtk"

PageLayout {
    id: root

    property string moduleId: "logs"
    property var allModules: [
        { id: "logs", name: "日志", icon: "📋", desc: "系统日志、内核日志、应用日志分析", status: "ready" },
        { id: "network", name: "网络", icon: "🌐", desc: "网络接口、路由表、DNS 配置、连通性检测", status: "ready" },
        { id: "system", name: "系统", icon: "⚙️", desc: "操作系统版本、内核信息、主机名、运行时间", status: "ready" },
        { id: "environment", name: "环境", icon: "🌏", desc: "环境变量、区域设置、PATH 配置检查", status: "ready" },
        { id: "listening", name: "监听任务", icon: "📡", desc: "端口监听、服务状态、进程关联检查", status: "planned" },
        { id: "netenv", name: "网络环境检查", icon: "🛡", desc: "代理配置、防火墙规则、VPN 状态检测", status: "planned" },
        { id: "disk", name: "磁盘健康", icon: "💾", desc: "SMART 信息、磁盘空间、文件系统检查", status: "planned" },
        { id: "security", name: "安全检查", icon: "🔒", desc: "用户权限、SUID 文件、开放端口安全审计", status: "planned" }
    ]

    signal moduleSwitchRequested(string moduleId)

    title: qsTr("📋 日志工具")

    property string currentPanel: "export"
    property var components: []
    property var selectedComponents: ({})
    property string debugLevel: "info"
    property bool isOperating: false
    property string statusMessage: ""

    Component.onCompleted: {
        components = logBackend.listComponents()
        initSelections()
    }

    function initSelections() {
        var map = {}
        for (var i = 0; i < components.length; i++)
            map[components[i]] = true
        selectedComponents = map
    }

    function getSelected() {
        var result = []
        for (var key in selectedComponents) {
            if (selectedComponents[key]) result.push(key)
        }
        return result
    }

    function selectAll(state) {
        var map = {}
        for (var i = 0; i < components.length; i++)
            map[components[i]] = state
        selectedComponents = map
    }

    Connections {
        target: logBackend
        function onExportFinished(success, path) {
            isOperating = false
            statusMessage = success ? qsTr("导出成功：") + path : qsTr("导出失败")
        }
        function onDebugModeChanged(component, enabled) {}
    }

    // ── TopBar actions ──
    topbarActions: RowLayout {
        spacing: 8

        DTKButton {
            text: qsTr("导出全部日志")
            highlighted: true
            onClicked: exportModal.visible = true
        }

        DTKButton {
            text: qsTr("开启调试模式")
            onClicked: debugModal.visible = true
        }
    }

    // ── Sidebar (module list, same as ModulePage) ──
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
    Item {
        anchors.fill: parent

        // Tab bar for switching between panels
        RowLayout {
            id: tabBar
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
                    Layout.preferredWidth: tabLabel.implicitWidth + 24
                    Layout.preferredHeight: 32
                    radius: 6
                    color: root.currentPanel === modelData.value ? Qt.rgba(0, 0.4, 0.8, 0.1) : "transparent"

                    Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: 13
                        font.bold: root.currentPanel === modelData.value
                        color: root.currentPanel === modelData.value ? DTKStyle.highlightColor : Qt.rgba(0, 0, 0, 0.5)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentPanel = modelData.value
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Export panel
        Flickable {
            id: exportPanel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: tabBar.bottom
            anchors.bottom: parent.bottom
            visible: currentPanel === "export"
            contentWidth: width
            contentHeight: exportColumn.implicitHeight + 48
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: exportColumn
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
                            model: root.components
                            delegate: DTKCheckBox {
                                text: modelData
                                checked: root.selectedComponents[modelData] === true
                                onToggled: { var map = root.selectedComponents; map[modelData] = checked; root.selectedComponents = map }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 6
                        Text {
                            text: qsTr("全选"); font.pixelSize: 12; color: DTKStyle.highlightColor
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectAll(true) }
                        }
                        Text { text: "|"; font.pixelSize: 12; color: Qt.rgba(0, 0, 0, 0.08) }
                        Text {
                            text: qsTr("全不选"); font.pixelSize: 12; color: DTKStyle.highlightColor
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectAll(false) }
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
                            id: exportPathField
                            Layout.fillWidth: true
                            text: Qt.homeDir + "/deepin-doctor-logs.tar.gz"
                            placeholderText: qsTr("输入导出路径...")
                            font.family: "monospace"
                        }

                        DTKButton {
                            text: qsTr("选择路径")
                            onClicked: fileDialog.open()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.statusMessage
                    visible: root.statusMessage !== ""
                    color: root.statusMessage.indexOf(qsTr("失败")) >= 0 ? mainWindow.errorColor : mainWindow.successColor
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }
            }
        }

        // Debug panel
        Flickable {
            id: debugPanel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: tabBar.bottom
            anchors.bottom: parent.bottom
            visible: currentPanel === "debug"
            contentWidth: width
            contentHeight: debugColumn.implicitHeight + 48
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: debugColumn
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
                            model: root.components
                            delegate: DTKCheckBox {
                                text: modelData
                                checked: root.selectedComponents[modelData] === true
                                onToggled: { var map = root.selectedComponents; map[modelData] = checked; root.selectedComponents = map }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 6
                        Text {
                            text: qsTr("全选"); font.pixelSize: 12; color: DTKStyle.highlightColor
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectAll(true) }
                        }
                        Text { text: "|"; font.pixelSize: 12; color: Qt.rgba(0, 0, 0, 0.08) }
                        Text {
                            text: qsTr("全不选"); font.pixelSize: 12; color: DTKStyle.highlightColor
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectAll(false) }
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("选择导出路径")
        folder: shortcuts.home
        nameFilters: ["TAR.GZ files (*.tar.gz)", "All files (*)"]
        selectExisting: false
        onAccepted: {
            var path = fileDialog.fileUrl.toString()
            if (path.indexOf("file://") === 0) path = path.substring(7)
            exportPathField.text = path
        }
    }

    // Export modal
    Rectangle {
        id: exportModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        visible: false
        z: 50
        MouseArea { anchors.fill: parent; onClicked: exportModal.visible = false }

        DTKBoxPanel {
            anchors.centerIn: parent
            width: 360
            height: modalExportCol.implicitHeight + 56
            radius: DTKStyle.popup.radius
            color: "#ffffff"
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: modalExportCol
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
                        onClicked: { exportModal.visible = false; root.isOperating = true; root.statusMessage = ""; logBackend.exportLogs(getSelected(), "collected", exportPathField.text) }
                    }
                    DTKButton {
                        Layout.fillWidth: true; text: qsTr("导出脚本")
                        onClicked: { exportModal.visible = false; root.statusMessage = qsTr("脚本已导出到 ~/export-logs.sh") }
                    }
                    DTKButton {
                        Layout.fillWidth: true; text: qsTr("复制命令")
                        onClicked: { exportModal.visible = false; root.statusMessage = qsTr("命令已复制到剪贴板") }
                    }
                }
            }
        }
    }

    // Debug modal
    Rectangle {
        id: debugModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        visible: false
        z: 50
        MouseArea { anchors.fill: parent; onClicked: debugModal.visible = false }

        DTKBoxPanel {
            anchors.centerIn: parent
            width: 360
            height: modalDebugCol.implicitHeight + 56
            radius: DTKStyle.popup.radius
            color: "#ffffff"
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: modalDebugCol
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
                            debugModal.visible = false; root.isOperating = true; root.statusMessage = ""
                            var success = logBackend.setDebugMode(getSelected(), true)
                            root.statusMessage = success ? qsTr("调试模式已开启") : qsTr("开启调试失败")
                            root.isOperating = false
                        }
                    }
                    DTKButton {
                        Layout.fillWidth: true; text: qsTr("导出脚本")
                        onClicked: { debugModal.visible = false; root.statusMessage = qsTr("脚本已导出到 ~/enable-debug.sh") }
                    }
                    DTKButton {
                        Layout.fillWidth: true; text: qsTr("复制命令")
                        onClicked: { debugModal.visible = false; root.statusMessage = qsTr("命令已复制到剪贴板") }
                    }
                }
            }
        }
    }
}

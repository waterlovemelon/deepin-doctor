import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../dtk"

Item {
    id: root

    signal moduleClicked(string moduleId)

    readonly property var modules: [
        { id: "logs",        name: qsTr("日志"),          icon: "📋", desc: qsTr("系统日志、内核日志、应用日志分析"),        status: "ready",  color: "red" },
        { id: "network",     name: qsTr("网络"),          icon: "🌐", desc: qsTr("网络接口、路由表、DNS 配置、连通性检测"),  status: "ready",  color: "blue" },
        { id: "system",      name: qsTr("系统"),          icon: "⚙️", desc: qsTr("操作系统版本、内核信息、主机名、运行时间"), status: "ready",  color: "green" },
        { id: "environment", name: qsTr("环境"),          icon: "🌏", desc: qsTr("环境变量、区域设置、PATH 配置检查"),       status: "ready",  color: "orange" },
        { id: "keyring",     name: qsTr("密钥环"),        icon: "🔑", desc: qsTr("白盒密钥环文件检测与修复"),                status: "ready",  color: "cyan" },
        { id: "listening",   name: qsTr("监听任务"),      icon: "📡", desc: qsTr("端口监听、服务状态、进程关联检查"),        status: "planned", color: "purple" },
        { id: "netenv",      name: qsTr("网络环境检查"),  icon: "🛡", desc: qsTr("代理配置、防火墙规则、VPN 状态检测"),      status: "planned", color: "teal" },
        { id: "disk",        name: qsTr("磁盘健康"),      icon: "💾", desc: qsTr("SMART 信息、磁盘空间、文件系统检查"),      status: "planned", color: "indigo" },
        { id: "security",    name: qsTr("安全检查"),      icon: "🔒", desc: qsTr("用户权限、SUID 文件、开放端口安全审计"),   status: "planned", color: "brown" }
    ]

    function iconBoxColor(colorName) {
        var map = {
            "blue":   "#e8f0fe",
            "green":  "#e8f5e9",
            "orange": "#fff3e0",
            "red":    "#ffebee",
            "purple": "#f3e5f5",
            "teal":   "#e0f2f1",
            "indigo": "#e8eaf6",
            "brown":  "#efebe9",
            "cyan":   "#e0f7fa"
        }
        return map[colorName] || "#f5f5f5"
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: grid.implicitHeight + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Grid {
            id: grid
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            columns: 4
            spacing: 12

            Repeater {
                model: root.modules

                delegate: Item {
                    id: cardWrapper
                    width: Math.floor((grid.width - grid.spacing * (grid.columns - 1)) / grid.columns)
                    height: 110

                    MouseArea {
                        id: cardMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moduleClicked(modelData.id)
                    }

                    DTKBoxPanel {
                        anchors.fill: parent
                        backgroundFlowsHovered: true
                        hovered: cardMouseArea.containsMouse

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    radius: DTKStyle.control.radius
                                    color: root.iconBoxColor(modelData.color)

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        font.pixelSize: 18
                                    }
                                }

                                Text {
                                    text: modelData.name
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: mainWindow.textColor
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    Layout.preferredWidth: badgeLabel.implicitWidth + 12
                                    Layout.preferredHeight: badgeLabel.implicitHeight + 6
                                    radius: DTKStyle.control.radius
                                    color: modelData.status === "ready" ? "#e8f5e9" : Qt.rgba(0, 0, 0, 0.05)

                                    Text {
                                        id: badgeLabel
                                        anchors.centerIn: parent
                                        text: modelData.status === "ready" ? qsTr("可用") : qsTr("规划中")
                                        font.pixelSize: 10
                                        color: modelData.status === "ready" ? mainWindow.successColor : Qt.rgba(0, 0, 0, 0.4)
                                    }
                                }
                            }

                            Text {
                                id: descText
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: modelData.desc
                                font.pixelSize: 11
                                color: Qt.rgba(0, 0, 0, 0.4)
                                elide: Text.ElideRight
                                wrapMode: Text.WordWrap
                                lineHeight: 1.3
                                maximumLineCount: 2
                            }
                        }
                    }
                }
            }
        }
    }
}

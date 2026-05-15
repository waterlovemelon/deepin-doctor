import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    signal moduleClicked(string moduleId)

    readonly property var modules: [
        { id: "logs",        name: qsTr("日志"),          icon: "📋", desc: qsTr("系统日志、内核日志、应用日志分析"),        status: "ready",  color: "red" },
        { id: "network",     name: qsTr("网络"),          icon: "🌐", desc: qsTr("网络接口、路由表、DNS 配置、连通性检测"),  status: "ready",  color: "blue" },
        { id: "system",      name: qsTr("系统"),          icon: "⚙️", desc: qsTr("操作系统版本、内核信息、主机名、运行时间"), status: "ready",  color: "green" },
        { id: "environment", name: qsTr("环境"),          icon: "🌏", desc: qsTr("环境变量、区域设置、PATH 配置检查"),       status: "ready",  color: "orange" },
        { id: "listening",   name: qsTr("监听任务"),      icon: "📡", desc: qsTr("端口监听、服务状态、进程关联检查"),        status: "planned", color: "purple" },
        { id: "netenv",      name: qsTr("网络环境检查"),  icon: "🛡", desc: qsTr("代理配置、防火墙规则、VPN 状态检测"),      status: "planned", color: "teal" },
        { id: "disk",        name: qsTr("磁盘健康"),      icon: "💾", desc: qsTr("SMART 信息、磁盘空间、文件系统检查"),      status: "planned", color: "indigo" },
        { id: "security",    name: qsTr("安全检查"),      icon: "🔒", desc: qsTr("用户权限、SUID 文件、开放端口安全审计"),   status: "planned", color: "brown" }
    ]

    // Map color names to icon box background colors
    function iconBoxColor(colorName) {
        var map = {
            "blue":   "#e8f0fe",
            "green":  "#e8f5e9",
            "orange": "#fff3e0",
            "red":    "#ffebee",
            "purple": "#f3e5f5",
            "teal":   "#e0f2f1",
            "indigo": "#e8eaf6",
            "brown":  "#efebe9"
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

                    Rectangle {
                        id: card
                        anchors.fill: parent
                        color: "#ffffff"
                        border.color: cardMouseArea.containsMouse ? mainWindow.accentColor : "#e0e0e0"
                        border.width: cardMouseArea.containsMouse ? 2 : 1
                        radius: 8

                        Behavior on border.color {
                            ColorAnimation { duration: 150 }
                        }

                        ToolTip {
                            visible: cardMouseArea.containsMouse && (nameText.truncated || descText.truncated)
                            text: {
                                var parts = []
                                if (nameText.truncated) parts.push(modelData.name)
                                if (descText.truncated) parts.push(modelData.desc)
                                return parts.join("\n")
                            }
                            delay: 600
                        }

                        MouseArea {
                            id: cardMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.moduleClicked(modelData.id)
                        }

                        ColumnLayout {
                            id: cardContent
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8

                            // Top row: icon box + name + badge
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                // Colored icon box
                                Rectangle {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    radius: 8
                                    color: root.iconBoxColor(modelData.color)

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        font.pixelSize: 18
                                    }
                                }

                                // Module name
                                Text {
                                    id: nameText
                                    text: modelData.name
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: mainWindow.textColor
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                // Status badge
                                Rectangle {
                                    Layout.preferredWidth: badgeLabel.implicitWidth + 12
                                    Layout.preferredHeight: badgeLabel.implicitHeight + 6
                                    radius: 4
                                    color: modelData.status === "ready" ? "#e8f5e9" : "#f5f5f5"

                                    Text {
                                        id: badgeLabel
                                        anchors.centerIn: parent
                                        text: modelData.status === "ready" ? qsTr("可用") : qsTr("规划中")
                                        font.pixelSize: 10
                                        color: modelData.status === "ready" ? mainWindow.successColor : mainWindow.mutedTextColor
                                    }
                                }
                            }

                            // Description - fixed 2 lines, ellipsis
                            Text {
                                id: descText
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: modelData.desc
                                font.pixelSize: 11
                                color: "#888888"
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

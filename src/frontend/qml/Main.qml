import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "pages"

ApplicationWindow {
    id: mainWindow

    visible: true
    width: 1180
    height: 820
    minimumWidth: 960
    minimumHeight: 680
    title: qsTr("Deepin Doctor")
    color: backgroundColor

    readonly property color backgroundColor: "#0b1020"
    readonly property color surfaceColor: "#121a2d"
    readonly property color elevatedSurfaceColor: "#18233b"
    readonly property color borderColor: "#2d3b5d"
    readonly property color textColor: "#f3f7ff"
    readonly property color mutedTextColor: "#8e9bb7"
    readonly property color accentColor: "#56b3ff"
    readonly property color successColor: "#42c78f"
    readonly property color warningColor: "#ffb24d"
    readonly property color errorColor: "#ff6f7d"
    readonly property int radiusSm: 10
    readonly property int radiusMd: 16
    readonly property int radiusLg: 24
    readonly property int spacingXs: 8
    readonly property int spacingSm: 12
    readonly property int spacingMd: 16
    readonly property int spacingLg: 24
    readonly property int durationFast: 140
    readonly property int durationNormal: 220

    property var selectedModules: []
    property var exportData: null

    function goBack() {
        if (stackView.depth > 1)
            stackView.pop()
    }

    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0a0f1d" }
            GradientStop { position: 0.55; color: mainWindow.backgroundColor }
            GradientStop { position: 1.0; color: "#0f1730" }
        }
    }

    header: Item {
        implicitHeight: 108

        Rectangle {
            anchors.fill: parent
            color: "transparent"
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: mainWindow.spacingLg
            height: parent.height - mainWindow.spacingLg
            radius: mainWindow.radiusLg
            color: Qt.rgba(18 / 255, 26 / 255, 45 / 255, 0.94)
            border.color: mainWindow.borderColor
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: mainWindow.spacingLg
                spacing: mainWindow.spacingLg

                Rectangle {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 52
                    radius: mainWindow.radiusMd
                    color: mainWindow.elevatedSurfaceColor
                    border.color: mainWindow.borderColor
                    border.width: 1

                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 10
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            ctx.strokeStyle = mainWindow.accentColor
                            ctx.lineWidth = 2
                            ctx.lineCap = "round"
                            ctx.beginPath()
                            ctx.moveTo(width * 0.1, height * 0.68)
                            ctx.lineTo(width * 0.34, height * 0.52)
                            ctx.lineTo(width * 0.5, height * 0.7)
                            ctx.lineTo(width * 0.76, height * 0.28)
                            ctx.lineTo(width * 0.9, height * 0.44)
                            ctx.stroke()
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: qsTr("Deepin Doctor")
                        color: mainWindow.textColor
                        font.pixelSize: 28
                        font.bold: true
                    }

                    Label {
                        text: stackView.depth > 1
                              ? qsTr("Diagnostic export workspace")
                              : qsTr("Diagnostic workspace console")
                        color: mainWindow.mutedTextColor
                        font.pixelSize: 13
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    radius: 999
                    color: Qt.rgba(86 / 255, 179 / 255, 1, 0.12)
                    border.color: Qt.rgba(86 / 255, 179 / 255, 1, 0.36)
                    border.width: 1
                    implicitWidth: badgeRow.implicitWidth + mainWindow.spacingMd
                    implicitHeight: badgeRow.implicitHeight + mainWindow.spacingSm

                    RowLayout {
                        id: badgeRow
                        anchors.centerIn: parent
                        spacing: mainWindow.spacingXs

                        Rectangle {
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 8
                            radius: 4
                            color: stackView.depth > 1 ? mainWindow.warningColor : mainWindow.successColor
                        }

                        Label {
                            text: stackView.depth > 1 ? qsTr("Export Flow") : qsTr("Ready")
                            color: mainWindow.textColor
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }
            }
        }
    }

    footer: Item {
        implicitHeight: 54

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: mainWindow.spacingLg
            height: parent.height - mainWindow.spacingLg
            radius: mainWindow.radiusMd
            color: Qt.rgba(18 / 255, 26 / 255, 45 / 255, 0.88)
            border.color: mainWindow.borderColor
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: mainWindow.spacingMd
                spacing: mainWindow.spacingMd

                Label {
                    text: qsTr("Workspace")
                    color: mainWindow.mutedTextColor
                    font.pixelSize: 12
                }

                Label {
                    text: stackView.depth > 1 ? qsTr("Export") : qsTr("Diagnostics")
                    color: mainWindow.textColor
                    font.pixelSize: 12
                    font.bold: true
                }

                Item {
                    Layout.fillWidth: true
                }

                Label {
                    text: qsTr("Page %1").arg(stackView.depth)
                    color: mainWindow.mutedTextColor
                    font.pixelSize: 12
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: header ? header.height : 0
        anchors.bottomMargin: footer ? footer.height : 0

        Rectangle {
            anchors.fill: parent
            anchors.margins: mainWindow.spacingLg
            radius: mainWindow.radiusLg
            color: Qt.rgba(18 / 255, 26 / 255, 45 / 255, 0.9)
            border.color: mainWindow.borderColor
            border.width: 1
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: mainWindow.spacingLg + 1
            height: 72
            radius: mainWindow.radiusLg
            color: Qt.rgba(24 / 255, 35 / 255, 59 / 255, 0.78)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: mainWindow.spacingLg
                anchors.rightMargin: mainWindow.spacingLg
                spacing: mainWindow.spacingMd

                Button {
                    visible: stackView.depth > 1
                    enabled: visible
                    text: qsTr("Back")
                    onClicked: mainWindow.goBack()
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: stackView.depth > 1 ? qsTr("Export Results") : qsTr("System Diagnosis")
                        color: mainWindow.textColor
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Label {
                        text: stackView.depth > 1
                              ? qsTr("Package and save collected diagnostics")
                              : qsTr("Collect, inspect, and review system health data")
                        color: mainWindow.mutedTextColor
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    radius: 999
                    color: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.05)
                    border.color: mainWindow.borderColor
                    border.width: 1
                    implicitWidth: navMeta.implicitWidth + mainWindow.spacingMd
                    implicitHeight: navMeta.implicitHeight + mainWindow.spacingSm

                    RowLayout {
                        id: navMeta
                        anchors.centerIn: parent
                        spacing: mainWindow.spacingXs

                        Label {
                            text: stackView.depth > 1 ? qsTr("Esc") : qsTr("Main")
                            color: mainWindow.textColor
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Label {
                            text: stackView.depth > 1 ? qsTr("Back shortcut") : qsTr("Home workspace")
                            color: mainWindow.mutedTextColor
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: mainWindow.spacingLg + 1
            anchors.topMargin: mainWindow.spacingLg + 85

            StackView {
                id: stackView
                anchors.fill: parent
                clip: true
                initialItem: mainPageComponent

                pushEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            property: "x"
                            from: stackView.width * 0.04
                            to: 0
                            duration: mainWindow.durationNormal
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: mainWindow.durationNormal
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                pushExit: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            property: "x"
                            from: 0
                            to: -stackView.width * 0.015
                            duration: mainWindow.durationFast
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            property: "opacity"
                            from: 1
                            to: 0.35
                            duration: mainWindow.durationFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                popEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            property: "x"
                            from: -stackView.width * 0.03
                            to: 0
                            duration: mainWindow.durationNormal
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            property: "opacity"
                            from: 0.45
                            to: 1
                            duration: mainWindow.durationNormal
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                popExit: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            property: "x"
                            from: 0
                            to: stackView.width * 0.035
                            duration: mainWindow.durationFast
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: mainWindow.durationFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    Component {
        id: mainPageComponent

        MainPage {
            id: mainPage
            onExportRequested: function(resultData) {
                mainWindow.exportData = resultData
                stackView.push(exportPageComponent)
            }
        }
    }

    Component {
        id: exportPageComponent

        ExportPage {
            id: exportPage
            exportData: mainWindow.exportData
            onBackRequested: mainWindow.goBack()
            onExportCompleted: function(outputPath) {
                console.log("Export completed:", outputPath)
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: stackView.depth > 1
        onActivated: mainWindow.goBack()
    }
}

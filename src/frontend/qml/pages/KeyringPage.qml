import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"
import "../dtk"

PageLayout {
    id: root

    property var userList: []
    property string selectedUser: ""
    property bool checkAllUsers: false
    property bool isRunning: false
    property string rawOutput: ""
    property var results: []  // [{user, wbStatus, defaultStatus, detail}]
    property string mode: "check"  // "check" or "fix"

    title: "🔑 " + qsTr("密钥环检查与修复")

    Component.onCompleted: {
        userList = processHelper.availableUsers()
        if (userList.length > 0) selectedUser = userList[0]
    }

    function statusLabel(s) {
        switch (s) {
        case "ok":      return qsTr("正常")
        case "bad":     return qsTr("损坏")
        case "missing": return qsTr("缺失")
        case "error":   return qsTr("错误")
        default:        return s || qsTr("未知")
        }
    }

    function statusColor(s) {
        switch (s) {
        case "ok":      return mainWindow.successColor
        case "bad":     return mainWindow.errorColor
        case "missing": return mainWindow.warningColor
        case "error":   return mainWindow.errorColor
        default:        return mainWindow.mutedTextColor
        }
    }

    function statusIcon(s) {
        switch (s) {
        case "ok":      return "✓"
        case "bad":     return "✗"
        case "missing": return "—"
        case "error":   return "!"
        default:        return "?"
        }
    }

    function parseOutput(output) {
        var lines = output.split("\n")
        var parsed = []
        var current = null

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].replace(/^\[wb-keyring-fix\]\s*/, "")

            // Match: user: whitebox=xxx, default=xxx
            var m = line.match(/^(\S+):\s*whitebox=(\S+),\s*default=(\S+)/)
            if (m) {
                if (current) parsed.push(current)
                current = { user: m[1], wbStatus: m[2], defaultStatus: m[3], detail: "" }
                continue
            }

            // Match detail lines
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

    function findScript() {
        return processHelper.findTool("wb-keyring-fix.sh")
    }

    function buildArgs(fixMode) {
        var args = []
        if (fixMode) args.push("--fix")
        if (checkAllUsers) {
            args.push("--all-users")
        } else if (selectedUser !== "") {
            args.push("--user=" + selectedUser)
        }
        return args
    }

    function runWithScript(fixMode) {
        if (isRunning) return
        isRunning = true
        rawOutput = ""
        results = []
        mode = fixMode ? "fix" : "check"

        var script = findScript()
        if (!script) {
            rawOutput = qsTr("错误：找不到 wb-keyring-fix.sh 脚本，请确认已安装 deepin-doctor")
            isRunning = false
            return
        }

        var output = processHelper.run(script, buildArgs(fixMode), 60000)
        rawOutput = output
        results = parseOutput(output)
        isRunning = false
    }

    function runCheck() { runWithScript(false) }
    function runFix() { runWithScript(true) }

    // ── TopBar actions ──
    topbarActions: RowLayout {
        spacing: 8

        DTKButton {
            text: qsTr("检测")
            highlighted: true
            enabled: !isRunning
            onClicked: root.runCheck()
        }

        DTKButton {
            text: qsTr("修复")
            enabled: !isRunning
            onClicked: root.runFix()
        }
    }

    // ── Content ──
    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 48
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 16

            // ── User Selection ──
            DTKBoxPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: userColumn.implicitHeight + 32

                ColumnLayout {
                    id: userColumn
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
                            checked: root.checkAllUsers
                            onToggled: root.checkAllUsers = checked
                        }

                        Item { Layout.fillWidth: true }

                        ComboBox {
                            id: userCombo
                            Layout.preferredWidth: 200
                            model: root.userList
                            currentIndex: root.userList.indexOf(root.selectedUser)
                            enabled: !root.checkAllUsers
                            onCurrentTextChanged: {
                                if (currentIndex >= 0) root.selectedUser = currentText
                            }
                        }
                    }
                }
            }

            // ── Running indicator ──
            DTKBoxPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: runColumn.implicitHeight + 32
                visible: isRunning

                ColumnLayout {
                    id: runColumn
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
                            text: root.mode === "fix" ? qsTr("正在修复密钥环...") : qsTr("正在检测密钥环...")
                            font.bold: true
                            font.pixelSize: 13
                            color: mainWindow.textColor
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // ── Results ──
            DTKBoxPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(200, resultsColumn.implicitHeight + 32)
                visible: results.length > 0

                ColumnLayout {
                    id: resultsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: root.mode === "fix" ? qsTr("修复结果") : qsTr("检测结果")
                            font.pixelSize: 14
                            font.bold: true
                            color: mainWindow.textColor
                        }

                        Rectangle {
                            Layout.preferredWidth: countLabel.implicitWidth + 16
                            Layout.preferredHeight: countLabel.implicitHeight + 8
                            radius: 10
                            color: {
                                var hasIssue = false
                                for (var i = 0; i < results.length; i++) {
                                    if (results[i].wbStatus !== "ok") { hasIssue = true; break }
                                }
                                return hasIssue ? mainWindow.warningColor : mainWindow.successColor
                            }
                            Text {
                                id: countLabel
                                anchors.centerIn: parent
                                text: results.length + qsTr(" 个用户")
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
                        model: root.results

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: rowContent.implicitHeight + 16
                            color: index % 2 === 0 ? "transparent" : Qt.rgba(0, 0, 0, 0.02)

                            RowLayout {
                                id: rowContent
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                // User column
                                Text {
                                    text: modelData.user
                                    font.pixelSize: 12
                                    font.family: "monospace"
                                    color: mainWindow.textColor
                                    Layout.preferredWidth: 120
                                    elide: Text.ElideRight
                                }

                                // WB status
                                RowLayout {
                                    Layout.preferredWidth: 100
                                    spacing: 4

                                    Rectangle {
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        radius: 10
                                        color: Qt.rgba(
                                            root.statusColor(modelData.wbStatus).r,
                                            root.statusColor(modelData.wbStatus).g,
                                            root.statusColor(modelData.wbStatus).b, 0.12)

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.statusIcon(modelData.wbStatus)
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.statusColor(modelData.wbStatus)
                                        }
                                    }

                                    Text {
                                        text: root.statusLabel(modelData.wbStatus)
                                        font.pixelSize: 12
                                        color: root.statusColor(modelData.wbStatus)
                                    }
                                }

                                // Default status
                                RowLayout {
                                    Layout.preferredWidth: 100
                                    spacing: 4

                                    Rectangle {
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        radius: 10
                                        color: Qt.rgba(
                                            root.statusColor(modelData.defaultStatus).r,
                                            root.statusColor(modelData.defaultStatus).g,
                                            root.statusColor(modelData.defaultStatus).b, 0.12)

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.statusIcon(modelData.defaultStatus)
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.statusColor(modelData.defaultStatus)
                                        }
                                    }

                                    Text {
                                        text: root.statusLabel(modelData.defaultStatus)
                                        font.pixelSize: 12
                                        color: root.statusColor(modelData.defaultStatus)
                                    }
                                }

                                // Detail
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

            // ── Raw output ──
            DTKBoxPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: rawColumn.implicitHeight + 32
                visible: rawOutput !== ""

                ColumnLayout {
                    id: rawColumn
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
                                    clipboardInput.text = root.rawOutput
                                    clipboardInput.selectAll()
                                    clipboardInput.copy()
                                    copyToast.visible = true
                                    copyToastTimer.restart()
                                }
                            }
                        }

                        Text {
                            id: copyToast
                            text: qsTr("已复制")
                            font.pixelSize: 11
                            color: mainWindow.successColor
                            visible: false
                            Timer { id: copyToastTimer; interval: 1500; onTriggered: copyToast.visible = false }
                        }
                    }

                    TextInput {
                        id: clipboardInput
                        visible: false
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(300, rawText.implicitHeight + 16)
                        color: Qt.rgba(0, 0, 0, 0.03)
                        radius: 4

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 8
                            contentWidth: width
                            contentHeight: rawText.implicitHeight
                            clip: true

                            Text {
                                id: rawText
                                width: parent.width
                                text: root.rawOutput
                                font.pixelSize: 11
                                font.family: "monospace"
                                color: Qt.rgba(0, 0, 0, 0.6)
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            // ── Empty state ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                color: "transparent"
                visible: results.length === 0 && !isRunning && rawOutput === ""

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
}

// DTK TextField - pure QML reimplementation of org.deepin.dtk TextField
import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
    id: control

    // Alert support (from upstream DTK TextField)
    property string alertText: ""
    property bool showAlert: false
    property int alertDuration: 3000
    property color backgroundColor: showAlert ? DTKStyle.edit.alertBackground : DTKStyle.edit.background

    implicitWidth: Math.max(DTKStyle.edit.width, placeholderText.implicitWidth + leftPadding + rightPadding)
    implicitHeight: DTKStyle.edit.textFieldHeight
    padding: DTKStyle.control.padding
    font.pixelSize: 13
    color: Qt.rgba(0, 0, 0, 0.7)
    placeholderTextColor: DTKStyle.edit.placeholderText
    verticalAlignment: TextInput.AlignVCenter
    selectByMouse: true
    selectionColor: Qt.rgba(0, 129, 255, 0.3)
    selectedTextColor: Qt.rgba(0, 0, 0, 0.7)
    opacity: enabled ? 1.0 : 0.4

    background: Rectangle {
        radius: DTKStyle.control.radius
        color: control.activeFocus ? DTKStyle.edit.backgroundFocus : control.backgroundColor
        border.color: control.activeFocus ? DTKStyle.edit.borderFocus : DTKStyle.edit.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    // Auto-dismiss alert after duration
    onShowAlertChanged: {
        if (showAlert && alertDuration > 0) {
            alertDismissTimer.restart()
        }
    }

    Timer {
        id: alertDismissTimer
        interval: control.alertDuration
        onTriggered: control.showAlert = false
    }
}

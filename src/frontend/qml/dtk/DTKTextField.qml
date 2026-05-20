// DTK TextField - pure QML reimplementation of org.deepin.dtk TextField
import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
    id: control

    implicitWidth: Math.max(DTKStyle.edit.width, placeholderText.implicitWidth + leftPadding + rightPadding)
    implicitHeight: DTKStyle.edit.textFieldHeight
    padding: DTKStyle.control.padding
    font.pixelSize: 13
    color: Qt.rgba(0, 0, 0, 0.7)
    placeholderTextColor: DTKStyle.edit.placeholderText
    verticalAlignment: TextInput.AlignVCenter
    selectByMouse: true
    selectionColor: Qt.rgba(0, 102, 204, 0.3)
    selectedTextColor: Qt.rgba(0, 0, 0, 0.7)
    opacity: enabled ? 1.0 : 0.4

    background: Rectangle {
        radius: DTKStyle.control.radius
        color: activeFocus ? DTKStyle.edit.backgroundFocus : DTKStyle.edit.background
        border.color: activeFocus ? DTKStyle.edit.borderFocus : DTKStyle.edit.border
        border.width: activeFocus ? 1 : 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }
}

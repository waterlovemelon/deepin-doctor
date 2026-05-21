// DTK TextArea - multi-line text input with DTK styling
// Pure QML reimplementation extending QtQuick.Controls TextArea
import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls

Controls.TextArea {
    id: control

    implicitWidth: DTKStyle.edit.width
    implicitHeight: DTKStyle.edit.textAreaHeight
    padding: DTKStyle.control.padding
    font.pixelSize: 13
    color: Qt.rgba(0, 0, 0, 0.7)
    placeholderTextColor: DTKStyle.edit.placeholderText
    selectByMouse: true
    selectionColor: Qt.rgba(0, 129, 255, 0.3)
    selectedTextColor: Qt.rgba(0, 0, 0, 0.7)
    wrapMode: Controls.TextArea.Wrap
    opacity: enabled ? 1.0 : 0.4

    background: Rectangle {
        radius: DTKStyle.control.radius
        color: control.activeFocus ? DTKStyle.edit.backgroundFocus : DTKStyle.edit.background
        border.color: control.activeFocus ? DTKStyle.edit.borderFocus : DTKStyle.edit.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }
}

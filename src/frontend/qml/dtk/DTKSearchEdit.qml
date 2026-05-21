// DTK SearchEdit - search input with magnifier icon and clear button
// Pure QML reimplementation of org.deepin.dtk/SearchEdit
import QtQuick 2.11
import QtQuick.Layouts 1.11

Item {
    id: control

    property string text: textField.text
    property string placeholderText: qsTr("Search")
    property alias enabled: textField.enabled

    signal accepted()
    signal textChanged(string text)

    implicitWidth: DTKStyle.edit.width
    implicitHeight: DTKStyle.edit.textFieldHeight

    Rectangle {
        anchors.fill: parent
        radius: DTKStyle.control.radius
        color: textField.activeFocus ? DTKStyle.edit.backgroundFocus : DTKStyle.edit.background
        border.color: textField.activeFocus ? DTKStyle.edit.borderFocus : DTKStyle.edit.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: DTKStyle.searchEdit.iconLeftMargin
        anchors.rightMargin: DTKStyle.searchEdit.iconRightMargin
        spacing: 4

        // Search icon
        Text {
            text: "🔍"  // 🔍
            font.pixelSize: DTKStyle.searchEdit.iconSize
            color: Qt.rgba(0, 0, 0, 0.4)
            Layout.alignment: Qt.AlignVCenter

            // Fallback: simple magnifier shape using text
            visible: true
        }

        // Text field
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextInput {
                id: textField
                anchors.fill: parent
                anchors.topMargin: DTKStyle.control.padding
                anchors.bottomMargin: DTKStyle.control.padding
                font.pixelSize: 13
                color: Qt.rgba(0, 0, 0, 0.7)
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                selectionColor: Qt.rgba(0, 129, 255, 0.3)
                clip: true

                onAccepted: control.accepted()
                onTextChanged: control.textChanged(text)

                // Placeholder
                Text {
                    anchors.fill: parent
                    anchors.verticalCenter: parent.verticalCenter
                    text: control.placeholderText
                    font: parent.font
                    color: DTKStyle.edit.placeholderText
                    verticalAlignment: Text.AlignVCenter
                    visible: !textField.text && !textField.activeFocus
                }
            }
        }

        // Clear button
        Item {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter
            visible: textField.text.length > 0

            Rectangle {
                anchors.centerIn: parent
                width: 14
                height: 14
                radius: 7
                color: clearMouseArea.containsMouse ? Qt.rgba(0, 0, 0, 0.15) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "✕"  // ✕
                    font.pixelSize: 9
                    color: Qt.rgba(0, 0, 0, 0.5)
                }
            }

            MouseArea {
                id: clearMouseArea
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    textField.text = ""
                    textField.forceActiveFocus()
                }
            }
        }
    }
}

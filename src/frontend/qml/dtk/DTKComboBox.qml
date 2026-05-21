// DTK ComboBox - dropdown selector with DTK styling
// Pure QML reimplementation extending QtQuick.Controls ComboBox
import QtQuick 2.11
import QtQuick.Controls 2.4 as Controls
import QtQuick.Layouts 1.11

Controls.ComboBox {
    id: control

    implicitWidth: DTKStyle.comboBox.width
    implicitHeight: DTKStyle.comboBox.height
    padding: DTKStyle.comboBox.padding
    opacity: enabled ? 1.0 : 0.4

    // Content item (selected text + arrow)
    contentItem: Item {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: DTKStyle.comboBox.padding
            anchors.rightMargin: DTKStyle.comboBox.padding

            Text {
                text: control.displayText
                font.pixelSize: 13
                color: Qt.rgba(0, 0, 0, 0.7)
                elide: Text.ElideRight
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
            }

            // Arrow indicator
            Text {
                text: "▼"  // ▼
                font.pixelSize: 8
                color: Qt.rgba(0, 0, 0, 0.5)
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // Hide default indicator (arrow is drawn inside contentItem)
    indicator: Item {}

    // Background
    background: Rectangle {
        implicitWidth: DTKStyle.comboBox.width
        implicitHeight: DTKStyle.comboBox.height
        radius: DTKStyle.control.radius
        color: control.pressed ? DTKStyle.button.bgPressed
               : control.hovered ? DTKStyle.button.bgHovered
               : DTKStyle.edit.background
        border.color: control.activeFocus ? DTKStyle.edit.borderFocus : DTKStyle.edit.border
        border.width: 1

        // Inner highlight
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Qt.rgba(1, 1, 1, 0.1)
            visible: !control.pressed
        }
    }

    // Popup (dropdown)
    popup: Controls.Popup {
        y: control.height
        width: control.width
        implicitHeight: contentItem.implicitHeight + 2
        padding: 2

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex

            Controls.ScrollIndicator.vertical: Controls.ScrollIndicator { }
        }

        background: Rectangle {
            radius: DTKStyle.control.radius
            color: DTKStyle.menu.background
            border.color: Qt.rgba(0, 0, 0, 0.08)
            border.width: 1
        }

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
        }
    }

    // Delegate
    delegate: Controls.ItemDelegate {
        width: control.width
        height: DTKStyle.menu.item.height
        highlighted: control.currentIndex === index

        contentItem: Text {
            text: modelData
            font.pixelSize: 13
            color: parent.highlighted ? DTKStyle.highlightColor : Qt.rgba(0, 0, 0, 0.7)
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: DTKStyle.comboBox.padding
        }

        background: Rectangle {
            color: parent.highlighted ? Qt.rgba(0, 129, 255, 0.1)
                   : parent.hovered ? Qt.rgba(0, 0, 0, 0.05)
                   : "transparent"
            radius: 4
        }
    }
}

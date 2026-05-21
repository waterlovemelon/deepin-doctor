// DTK MenuItem - menu item with DTK styling
// Pure QML reimplementation extending QtQuick.Controls MenuItem
import QtQuick 2.11
import QtQuick.Controls 2.4 as Controls
import QtQuick.Layouts 1.11

Controls.MenuItem {
    id: control

    implicitHeight: DTKStyle.menu.item.height
    opacity: enabled ? 1.0 : 0.4

    contentItem: RowLayout {
        spacing: 8

        // Icon
        Text {
            text: control.icon.name ? "" : (control.icon.source ? "" : "")
            visible: false  // Icon support via icon.name/source
            font.pixelSize: DTKStyle.menu.item.iconSize
        }

        // Text
        Text {
            text: control.text
            font.pixelSize: 13
            color: control.highlighted ? DTKStyle.highlightColor : DTKStyle.menu.itemText
            Layout.fillWidth: true
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: 8
        }

        // Shortcut
        Text {
            text: control.action ? (control.action.shortcut || "") : ""
            font.pixelSize: 11
            color: Qt.rgba(0, 0, 0, 0.4)
            visible: text.length > 0
            rightPadding: 8
        }
    }

    background: Rectangle {
        implicitHeight: DTKStyle.menu.item.height
        radius: 4
        color: control.highlighted ? Qt.rgba(0, 129, 255, 0.1)
               : control.hovered ? Qt.rgba(0, 0, 0, 0.05)
               : "transparent"

        anchors.leftMargin: 4
        anchors.rightMargin: 4
    }

    indicator: Item {
        x: 8
        y: (parent.height - height) / 2
        width: 16
        height: 16

        Text {
            anchors.centerIn: parent
            text: "✓"
            font.pixelSize: 12
            color: DTKStyle.highlightColor
            visible: control.checked
        }
    }
}

// DTK ScrollBar - thin scrollbar that expands on hover
// Pure QML reimplementation extending QtQuick.Controls ScrollBar
import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls

Controls.ScrollBar {
    id: control

    property bool hovered: handleMouseArea.containsMouse || control.pressed
    property int normalWidth: DTKStyle.scrollBar.width
    property int expandedWidth: DTKStyle.scrollBar.activeWidth

    implicitWidth: normalWidth
    contentItem: Rectangle {
        id: handle
        implicitWidth: control.hovered ? control.expandedWidth : control.normalWidth
        implicitHeight: control.hovered ? control.expandedWidth : control.normalWidth
        radius: width / 2
        color: control.pressed ? DTKStyle.scrollBar.backgroundPressed
               : control.hovered ? DTKStyle.scrollBar.backgroundHovered
               : DTKStyle.scrollBar.background
        opacity: control.policy === Controls.ScrollBar.AlwaysOn || control.active ? 1.0 : 0.0

        Behavior on implicitWidth { NumberAnimation { duration: 120 } }
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            id: handleMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    background: Rectangle {
        implicitWidth: control.expandedWidth
        implicitHeight: control.expandedWidth
        radius: width / 2
        color: "transparent"
        opacity: control.hovered && control.active ? 0.15 : 0.0

        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}

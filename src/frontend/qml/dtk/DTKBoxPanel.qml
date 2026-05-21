// DTK BoxPanel - card container with border and shadow
// Pure QML reimplementation of org.deepin.dtk/BoxPanel
import QtQuick 2.15

Rectangle {
    id: panel

    property color insideBorderColor: DTKStyle.boxPanel.insideBorder
    property color outsideBorderColor: DTKStyle.boxPanel.outsideBorder
    property color dropShadowColor: DTKStyle.boxPanel.dropShadow
    property color innerShadow1Color: DTKStyle.boxPanel.innerShadow1
    property color innerShadow2Color: DTKStyle.boxPanel.innerShadow2
    property bool backgroundFlowsHovered: false
    property bool hovered: false

    radius: DTKStyle.boxPanel.radius
    color: backgroundFlowsHovered && hovered ? Qt.rgba(0, 0, 0, 0.03) : "#ffffff"
    border.color: hovered ? DTKStyle.boxPanel.outsideBorderHovered : outsideBorderColor
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    // Inner highlight (top edge light)
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: innerShadow2Color
        visible: !hovered
    }
}

// DTK BoxPanel - card container with border and shadow
// Pure QML reimplementation of org.deepin.dtk/BoxPanel
import QtQuick 2.15

Rectangle {
    id: panel

    property color insideBorderColor: DTKStyle.boxPanel.insideBorder
    property color outsideBorderColor: DTKStyle.boxPanel.outsideBorder
    property bool backgroundFlowsHovered: false
    property bool hovered: false

    radius: DTKStyle.boxPanel.radius
    color: backgroundFlowsHovered && hovered ? Qt.rgba(0, 0, 0, 0.03) : "#ffffff"
    border.color: hovered ? Qt.rgba(0, 0, 0, 0.15) : outsideBorderColor
    border.width: 1

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Behavior on border.color {
        ColorAnimation { duration: 120 }
    }
}

// DTK HighlightPanel - selected item background
// Pure QML reimplementation of org.deepin.dtk/HighlightPanel
import QtQuick 2.15

Item {
    id: panel

    property color backgroundColor: DTKStyle.highlightPanel.background
    property color backgroundColorHovered: DTKStyle.highlightPanel.backgroundHovered
    property color dropShadowColor: DTKStyle.highlightPanel.dropShadow
    property color innerShadowColor: DTKStyle.highlightPanel.innerShadow
    property int radius: DTKStyle.highlightPanel.radius
    property bool hovered: false

    implicitWidth: DTKStyle.highlightPanel.width
    implicitHeight: DTKStyle.highlightPanel.height

    Rectangle {
        anchors.fill: parent
        color: panel.hovered ? panel.backgroundColorHovered : panel.backgroundColor
        radius: panel.radius

        Behavior on color { ColorAnimation { duration: 120 } }

        // Inner shadow (bottom edge dark)
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: panel.innerShadowColor
            visible: false  // subtle effect, enable if needed
        }
    }
}

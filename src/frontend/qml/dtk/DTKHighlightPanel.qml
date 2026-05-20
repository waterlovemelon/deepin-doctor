// DTK HighlightPanel - selected item background
// Pure QML reimplementation of org.deepin.dtk/HighlightPanel
import QtQuick 2.15

Item {
    id: panel

    property color backgroundColor: DTKStyle.highlightPanel.background
    property int radius: DTKStyle.highlightPanel.radius

    implicitWidth: 180
    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        color: panel.backgroundColor
        radius: panel.radius
    }
}

// DTK ItemDelegate - list item with highlight/hover states
// Pure QML reimplementation of org.deepin.dtk/ItemDelegate
import QtQuick 2.11
import QtQuick.Layouts 1.11

Item {
    id: delegate

    // Public API
    property string text: ""
    property string iconText: ""
    property bool checked: false
    property bool cascade: false
    property bool hovered: mouseArea.containsMouse
    property color checkedTextColor: DTKStyle.itemDelegate.checkedText
    property color normalTextColor: DTKStyle.itemDelegate.hoveredText
    property int radius: DTKStyle.control.radius
    property int checkIndicatorIconSize: DTKStyle.itemDelegate.checkIndicatorIconSize
    property alias contentItem: contentLoader.sourceComponent

    signal clicked()

    implicitWidth: DTKStyle.itemDelegate.width
    implicitHeight: DTKStyle.itemDelegate.height

    // Background: highlight when checked, cascade on hover, subtle default
    Rectangle {
        anchors.fill: parent
        radius: delegate.radius
        color: delegate.checked ? DTKStyle.highlightPanel.background
               : delegate.cascade ? DTKStyle.itemDelegate.cascadeColor
               : delegate.hovered ? DTKStyle.itemDelegate.normalColor
               : "transparent"
    }

    // Default content layout
    Loader {
        id: contentLoader
        anchors.fill: parent
        active: delegate.contentItem !== null

        // Fallback: simple icon + text row
        sourceComponent: RowLayout {
            spacing: DTKStyle.control.spacing

            Text {
                text: delegate.iconText
                font.pixelSize: DTKStyle.itemDelegate.iconSize / 1.5
                visible: delegate.iconText !== ""
                Layout.leftMargin: DTKStyle.control.padding
            }

            Text {
                text: delegate.text
                font.pixelSize: 13
                font.bold: true
                color: delegate.checked ? delegate.checkedTextColor : delegate.normalTextColor
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.rightMargin: DTKStyle.control.padding
            }
        }
    }

    // MouseArea must be AFTER contentLoader to be on top and receive events
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: delegate.clicked()
    }
}

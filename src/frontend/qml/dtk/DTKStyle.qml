// DTK design tokens extracted from FlowStyle.qml
// Pure QML, no C++ dependency
pragma Singleton
import QtQuick 2.15

QtObject {
    // System accent color (DTK Highlight equivalent)
    property color highlightColor: "#0066cc"
    property color highlightedText: "#ffffff"

    // Control tokens
    property QtObject control: QtObject {
        property int radius: 8
        property int spacing: 6
        property int padding: 6
        property int borderWidth: 1
        property color border: Qt.rgba(0, 0, 0, 0.1)
    }

    // Settings navigation
    property QtObject settings: QtObject {
        property QtObject navigation: QtObject {
            property int width: 190
            property int margin: 10
        }
        property QtObject content: QtObject {
            property int margin: 10
        }
    }

    // Button
    property QtObject button: QtObject {
        property int width: 140
        property int height: 36
        property int hPadding: 8
        property int vPadding: 4
        property int iconSize: 24

        // Normal button colors
        property color bgNormal: "#f7f7f7"
        property color bgHovered: "#e1e1e1"
        property color bgPressed: "#bcc4d0"
        property color textNormal: Qt.rgba(0, 0, 0, 0.7)
        property color textHovered: Qt.rgba(0, 0, 0, 1)
        property color textPressed: highlightColor
        property color insideBorder: Qt.rgba(1, 1, 1, 0.1)
        property color outsideBorder: Qt.rgba(0, 0, 0, 0.08)
    }

    // Highlighted (accent) button
    property QtObject highlightedButton: QtObject {
        property color bgNormal: Qt.lighter(highlightColor, 1.3)
        property color bgHovered: Qt.lighter(highlightColor, 1.5)
        property color bgPressed: Qt.darker(highlightColor, 1.2)
        property color textNormal: "#ffffff"
        property color border: Qt.rgba(0, 0, 0, 0.08)
    }

    // Checked button
    property QtObject checkedButton: QtObject {
        property color bgNormal: highlightColor
        property color bgHovered: Qt.lighter(highlightColor, 1.15)
        property color bgPressed: Qt.darker(highlightColor, 1.15)
        property color textNormal: highlightedText
    }

    // Icon button
    property QtObject iconButton: QtObject {
        property int backgroundSize: 36
        property int iconSize: 16
        property int padding: 9
    }

    // ItemDelegate
    property QtObject itemDelegate: QtObject {
        property int width: 204
        property int height: 40
        property int iconSize: 24
        property color normalColor: Qt.rgba(0, 0, 0, 0.05)
        property color cascadeColor: Qt.rgba(0, 0, 0, 0.15)
        property color checkedColor: highlightColor
        property color checkedText: highlightedText
        property color hoveredText: Qt.rgba(0, 0, 0, 0.7)
    }

    // HighlightPanel (selected item background)
    property QtObject highlightPanel: QtObject {
        property int radius: 8
        property color background: highlightColor
        property color backgroundHovered: Qt.lighter(highlightColor, 1.15)
    }

    // BoxPanel
    property QtObject boxPanel: QtObject {
        property int radius: 8
        property color insideBorder: Qt.rgba(1, 1, 1, 0.1)
        property color outsideBorder: Qt.rgba(0, 0, 0, 0.08)
    }

    // CheckBox
    property QtObject checkBox: QtObject {
        property int indicatorWidth: 16
        property int indicatorHeight: 16
        property int iconSize: 16
        property int padding: 2
        property int focusRadius: 4
    }

    // Edit (TextField / TextArea)
    property QtObject edit: QtObject {
        property int width: 180
        property int textFieldHeight: 36
        property int textAreaHeight: 100
        property color background: Qt.rgba(0, 0, 0, 0.08)
        property color backgroundFocus: Qt.rgba(0, 0, 0, 0.05)
        property color placeholderText: Qt.rgba(0, 0, 0, 0.4)
        property color border: Qt.rgba(0, 0, 0, 0.1)
        property color borderFocus: highlightColor
    }

    // ProgressBar
    property QtObject progressBar: QtObject {
        property int width: 300
        property int height: 6
        property int radius: 3
        property color background: Qt.rgba(0, 0, 0, 0.1)
        property color fill: highlightColor
    }

    // ScrollBar
    property QtObject scrollBar: QtObject {
        property int width: 4
        property int activeWidth: 12
        property color background: Qt.rgba(0, 0, 0, 0.3)
    }

    // TitleBar
    property QtObject titleBar: QtObject {
        property int height: 50
        property int iconSize: 32
        property int leftMargin: 10
    }

    // Popup
    property QtObject popup: QtObject {
        property int radius: 18
        property int padding: 10
    }

    // Menu
    property QtObject menu: QtObject {
        property int radius: 12
        property int padding: 6
        property QtObject item: QtObject {
            property int height: 30
            property int iconSize: 14
        }
    }

    // BusyIndicator
    property QtObject busyIndicator: QtObject {
        property int size: 16
        property color fill: highlightColor
        property int animationDuration: 800
    }
}

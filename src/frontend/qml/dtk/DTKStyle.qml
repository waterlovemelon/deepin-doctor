// DTK design tokens extracted from dtkdeclarative FlowStyle.qml
// Pure QML, no C++ dependency — all D.Palette/D.ColorSelector resolved to concrete values
// Source: dtkdeclarative v6.7.41, light theme only
pragma Singleton
import QtQuick 2.15

QtObject {
    // Deepin system accent color (D.Color.Highlight equivalent)
    property color highlightColor: "#0081ff"
    property color highlightedText: "#ffffff"

    // ── Control (shared base tokens) ──────────────────────────────────
    property QtObject control: QtObject {
        property int radius: 8
        property int spacing: 6
        property int padding: 6
        property int borderWidth: 1
        property real focusBorderWidth: 2
        property real focusBorderPaddings: 1
        property color border: Qt.rgba(0, 0, 0, 0.05)
    }

    // ── Settings ──────────────────────────────────────────────────────
    property QtObject settings: QtObject {
        property QtObject title: QtObject {
            property int marginL1: 10
            property int marginL2: 30
            property int marginLOther: 50
        }
        property QtObject content: QtObject {
            property int margin: 10
            property int marginL1: 10
            property int marginL2: 30
            property int marginOther: 50
            property int resetButtonHeight: 90
        }
        property QtObject navigation: QtObject {
            property int width: 190
            property int height: 20
            property int margin: 10
            property int textVPadding: 10
        }
        property color background: "transparent"
        property color backgroundHovered: Qt.rgba(0, 0, 0, 0.1)
    }

    // ── Button ────────────────────────────────────────────────────────
    property QtObject button: QtObject {
        property int width: 140
        property int height: 36
        property int hPadding: control.radius   // 8
        property int vPadding: Math.floor(control.radius / 2)  // 4
        property int iconSize: 24

        property color bgNormal: "#f7f7f7"
        property color bgHovered: "#e1e1e1"
        property color bgPressed: "#bcc4d0"
        property color bgNormalDark: Qt.rgba(1, 1, 1, 0.1)
        property color textNormal: Qt.rgba(0, 0, 0, 1)
        property color textPressed: highlightColor
        property color insideBorder: Qt.rgba(1, 1, 1, 0.1)
        property color insideBorderHovered: Qt.rgba(1, 1, 1, 0.2)
        property color insideBorderPressed: Qt.rgba(1, 1, 1, 0.03)
        property color outsideBorder: Qt.rgba(0, 0, 0, 0.08)
        property color outsideBorderHovered: Qt.rgba(0, 0, 0, 0.2)
        property color dropShadow: Qt.rgba(0, 0, 0, 0.05)
        property color dropShadowHovered: Qt.rgba(0, 0, 0, 0.1)
        property color innerShadow1: Qt.rgba(0, 0, 0, 0.05)
        property color innerShadow2: Qt.rgba(1, 1, 1, 0.2)
        property color innerShadow2Hovered: Qt.rgba(1, 1, 1, 0.5)
    }

    // ── Highlighted (accent) button ───────────────────────────────────
    property QtObject highlightedButton: QtObject {
        property color bgNormal: "#3399ff"       // highlight lighter
        property color bgNormalDark: "#1a8cff"
        property color bgHovered: "#5cb3ff"      // highlight lighter+hover
        property color bgPressed: "#0066d6"      // highlight darker
        property color bgDisabled: "#3399ff"
        property color textNormal: "#ffffff"
        property color border: Qt.rgba(0, 129, 255, 0.2)
        property color borderHovered: Qt.rgba(0, 129, 255, 0.4)
        property color dropShadow: Qt.rgba(0, 80, 180, 0.4)
        property color innerShadow1: "#0052b3"
        property color innerShadow2: "transparent"
    }

    // ── Checked button ────────────────────────────────────────────────
    property QtObject checkedButton: QtObject {
        property color bgNormal: highlightColor
        property color bgHovered: "#1a8cff"
        property color bgPressed: "#0066d6"
        property color textNormal: highlightedText
        property color textHovered: Qt.lighter(highlightedText, 1.1)
        property color dropShadow: Qt.rgba(0, 129, 255, 0.4)
        property color innerShadow: "#0052b3"
    }

    // ── Window button ─────────────────────────────────────────────────
    property QtObject windowButton: QtObject {
        property int width: 50
        property int height: 50
        property color bgNormal: "transparent"
        property color bgHovered: Qt.rgba(0, 0, 0, 0.10)
        property color bgPressed: Qt.rgba(0, 0, 0, 0.15)
    }

    // ── Warning button ────────────────────────────────────────────────
    property QtObject warningButton: QtObject {
        property color text: "#ff5736"
    }

    // ── Icon button ───────────────────────────────────────────────────
    property QtObject iconButton: QtObject {
        property int backgroundSize: 36
        property int iconSize: 16
        property int padding: 9
    }

    // ── Tool button ───────────────────────────────────────────────────
    property QtObject toolButton: QtObject {
        property int width: 30
        property int height: 30
        property int iconSize: 16
        property int indicatorRightMargin: 6
    }

    // ── Floating button ───────────────────────────────────────────────
    property QtObject floatingButton: QtObject {
        property int size: 24
    }

    // ── CheckBox ──────────────────────────────────────────────────────
    property QtObject checkBox: QtObject {
        property int indicatorWidth: 16
        property int indicatorHeight: 16
        property int padding: 2
        property int iconSize: 16
        property int focusRadius: 4
    }

    // ── RadioButton ───────────────────────────────────────────────────
    property QtObject radioButton: QtObject {
        property int indicatorSize: 16
        property int iconSize: 16
        property int spacing: 8
        property int topPadding: 12
        property int bottomPadding: 12
    }

    // ── Switch ────────────────────────────────────────────────────────
    property QtObject switchControl: QtObject {
        property int indicatorWidth: 50
        property int indicatorHeight: 24
        property int handleWidth: 20
        property int handleHeight: 20
        property int handleRadius: 10
        property color bgOff: Qt.rgba(50/255, 50/255, 50/255, 0.2)
        property color bgOn: highlightColor
        property color handleOff: "#8c8c8c"
        property color handleOn: "#ffffff"
    }

    // ── ComboBox ──────────────────────────────────────────────────────
    property QtObject comboBox: QtObject {
        property int width: 240
        property int height: 36
        property int padding: 8
        property int spacing: 10
        property int iconSize: 12
        property int maxVisibleItems: 16
        property int indicatorSpacing: 7
        property int indicatorSize: 24
        property color separator: Qt.rgba(0, 0, 0, 0.05)
    }

    // ── ButtonBox ─────────────────────────────────────────────────────
    property QtObject buttonBox: QtObject {
        property int width: 30
        property int height: 30
        property int padding: 0
        property int spacing: 0
    }

    // ── Edit (TextField / TextArea) ───────────────────────────────────
    property QtObject edit: QtObject {
        property int width: 180
        property int actionIconSize: 24
        property int textFieldHeight: 36
        property int textAreaHeight: 100
        property color background: Qt.rgba(0, 0, 0, 0.08)
        property color backgroundDark: Qt.rgba(1, 1, 1, 0.05)
        property color backgroundFocus: Qt.rgba(0, 0, 0, 0.05)
        property color alertBackground: Qt.rgba(0.95, 0.22, 0.20, 0.15)
        property color placeholderText: Qt.rgba(0.33, 0.33, 0.33, 0.4)
        property color placeholderTextDark: Qt.rgba(1, 1, 1, 0.3)
        property color border: Qt.rgba(0, 0, 0, 0.1)
        property color borderFocus: highlightColor
    }

    // ── SearchEdit ────────────────────────────────────────────────────
    property QtObject searchEdit: QtObject {
        property int iconSize: 16
        property int iconLeftMargin: 10
        property int iconRightMargin: 7
        property int animationDuration: 200
    }

    // ── SpinBox ───────────────────────────────────────────────────────
    property QtObject spinBox: QtObject {
        property int width: 300
        property int height: 36
        property int spacing: 10
        property QtObject indicator: QtObject {
            property int width: 24
            property int height: 14
            property int iconSize: 24
            property int focusIconSize: 10
            property color background: Qt.rgba(0, 0, 0, 0.7)
            property color backgroundHovered: Qt.rgba(0, 0, 0, 0.6)
            property color backgroundPressed: Qt.rgba(0, 0, 0, 0.8)
        }
    }

    // ── Slider ────────────────────────────────────────────────────────
    property QtObject slider: QtObject {
        property int width: 120
        property int height: 60
        property int highlightMargin: -4
        property QtObject handle: QtObject {
            property int width: 20
            property int height: 24
        }
        property QtObject groove: QtObject {
            property int width: 100
            property int height: 4
            property color background: Qt.rgba(0, 0, 0, 0.2)
        }
    }

    // ── ProgressBar ───────────────────────────────────────────────────
    property QtObject progressBar: QtObject {
        property int width: 300
        property int height: 6
        property int radius: 3
        property color background: Qt.rgba(0, 0, 0, 0.1)
        property color fill: highlightColor
        property int indeterminateWidth: 90
        property int indeterminateDuration: 2000
        property color shadowColor: Qt.rgba(0, 129, 255, 0.4)
    }

    // ── Embedded ProgressBar ──────────────────────────────────────────
    property QtObject embeddedProgressBar: QtObject {
        property int width: 48
        property int height: 6
        property int contentHeight: 4
        property int backgroundRadius: 3
        property int contentRadius: 2
        property color background: Qt.rgba(0, 0, 0, 0.7)
        property color progressBackground: "#ffffff"
    }

    // ── ItemDelegate ──────────────────────────────────────────────────
    property QtObject itemDelegate: QtObject {
        property int width: 204
        property int height: 40
        property int iconSize: 24
        property int checkIndicatorIconSize: 24
        property color normalColor: Qt.rgba(0, 0, 0, 0.05)
        property color cascadeColor: Qt.rgba(0, 0, 0, 0.15)
        property color checkedColor: Qt.rgba(0, 0, 0, 0.15)
        property color checkBackgroundColor: Qt.rgba(0, 0, 0, 0.05)
        property color checkBackgroundColorHovered: Qt.rgba(0, 0, 0, 0.1)
        property color checkedText: highlightedText
        property color hoveredText: Qt.rgba(0, 0, 0, 0.7)
    }

    // ── HighlightPanel ────────────────────────────────────────────────
    property QtObject highlightPanel: QtObject {
        property int width: 180
        property int height: 30
        property int radius: 8
        property color background: highlightColor
        property color backgroundHovered: Qt.lighter(highlightColor, 1.15)
        property color dropShadow: Qt.rgba(0, 129, 255, 0.2)
        property color innerShadow: "#0052b3"
    }

    // ── BoxPanel ──────────────────────────────────────────────────────
    property QtObject boxPanel: QtObject {
        property int radius: 8
        property color insideBorder: Qt.rgba(1, 1, 1, 0.1)
        property color outsideBorder: Qt.rgba(0, 0, 0, 0.08)
        property color outsideBorderHovered: Qt.rgba(0, 0, 0, 0.15)
        property color dropShadow: Qt.rgba(0, 0, 0, 0.05)
        property color innerShadow1: Qt.rgba(0, 0, 0, 0.05)
        property color innerShadow2: Qt.rgba(1, 1, 1, 0.2)
    }

    // ── Dialog ────────────────────────────────────────────────────────
    property QtObject dialog: QtObject {
        property int width: 120
        property int height: 120
        property int contentHMargin: 10
        property int footerMargin: 10
        property int titleBarHeight: 50
        property int iconSize: 32
        property int radius: 18
    }

    property QtObject aboutDialog: QtObject {
        property int width: 540
        property int height: 290
        property int leftAreaWidth: 220
        property int bottomPadding: 20
        property int productIconHeight: 128
    }

    // ── Popup ─────────────────────────────────────────────────────────
    property QtObject popup: QtObject {
        property int width: 80
        property int height: 180
        property int radius: 18
        property int padding: 10
    }

    // ── Menu ──────────────────────────────────────────────────────────
    property QtObject menu: QtObject {
        property int padding: 10
        property int radius: 18
        property int margins: 0
        property color background: Qt.rgba(238/255, 238/255, 238/255, 0.8)
        property color backgroundDark: Qt.rgba(20/255, 20/255, 20/255, 0.8)
        property color itemText: Qt.rgba(0, 0, 0, 1)
        property color itemTextDark: Qt.rgba(1, 1, 1, 0.6)
        property color subMenuOpenedBackground: Qt.rgba(0, 0, 0, 0.15)
        property color separatorText: Qt.rgba(0, 0, 0, 0.5)
        property QtObject item: QtObject {
            property int width: 180
            property int height: 34
            property int iconSize: 14
        }
        property QtObject separator: QtObject {
            property int lineTopPadding: 6
            property int lineBottomPadding: 4
            property int lineHeight: 2
            property int topPadding: 11
            property int bottomPadding: 2
            property color lineColor: Qt.rgba(0, 0, 0, 0.1)
        }
    }

    // ── ToolTip ───────────────────────────────────────────────────────
    property QtObject toolTip: QtObject {
        property int verticalPadding: 4
        property int horizontalPadding: 5
        property int height: 24
    }

    property QtObject alertToolTip: QtObject {
        property int connectorWidth: 3
        property int connectorHeight: 12
        property int verticalPadding: 4
        property int horizontalPadding: 10
        property color text: "#e15736"
        property color textDark: "#e13669"
        property color background: Qt.rgba(247/255, 247/255, 247/255, 0.6)
        property color backgroundDark: Qt.rgba(59/255, 59/255, 59/255, 0.6)
        property color connectorBackground: "#ffffff"
    }

    // ── FloatingMessage ───────────────────────────────────────────────
    property QtObject floatingMessage: QtObject {
        property int maximumWidth: 450
        property int minimumHeight: 40
        property int closeButtonSize: 24
    }

    // ── FloatingPanel ─────────────────────────────────────────────────
    property QtObject floatingPanel: QtObject {
        property int width: 180
        property int height: 40
        property int radius: 14
        property color background: Qt.rgba(247/255, 247/255, 247/255, 0.6)
        property color backgroundDark: Qt.rgba(20/255, 20/255, 20/255, 0.6)
        property color dropShadow: Qt.rgba(0, 0, 0, 0.2)
        property color outsideBorder: Qt.rgba(0, 0, 0, 0.05)
        property color insideBorder: Qt.rgba(1, 1, 1, 0.05)
    }

    // ── ScrollBar ─────────────────────────────────────────────────────
    property QtObject scrollBar: QtObject {
        property int padding: 2
        property int width: 4
        property int activeWidth: 12
        property real hideOpacity: 0.0
        property int hidePauseDuration: 450
        property int hideDuration: 1500
        property color background: Qt.rgba(0, 0, 0, 0.5)
        property color backgroundHovered: Qt.rgba(0, 0, 0, 0.7)
        property color backgroundPressed: Qt.rgba(0, 0, 0, 0.4)
        property color outsideBorder: Qt.rgba(1, 1, 1, 0.1)
        property color insideBorder: Qt.rgba(0, 0, 0, 0.05)
    }

    // ── TitleBar ──────────────────────────────────────────────────────
    property QtObject titleBar: QtObject {
        property int height: 50
        property int iconSize: 32
        property int leftMargin: 10
    }

    // ── BusyIndicator ─────────────────────────────────────────────────
    property QtObject busyIndicator: QtObject {
        property int size: 16
        property int paddingFactor: 16
        property color fillColor: highlightColor
        property int animationDuration: 800
    }

    // ── StackView ─────────────────────────────────────────────────────
    property QtObject stackView: QtObject {
        property int animationDuration: 200
        property int animationEasingType: Easing.OutCubic
    }

    // ── BehindWindowBlur ──────────────────────────────────────────────
    property QtObject behindWindowBlur: QtObject {
        property color lightColor: Qt.rgba(235/255, 235/255, 235/255, 0.6)
        property color lightNoBlurColor: Qt.rgba(235/255, 235/255, 235/255, 1.0)
        property color darkColor: "#55000000"
        property color darkNoBlurColor: Qt.rgba(35/255, 35/255, 35/255, 1.0)
    }

    // ── Dial / PageIndicator ──────────────────────────────────────────
    property QtObject dial: QtObject {
        property int size: 100
    }
    property QtObject pageIndicator: QtObject {
        property int width: 8
        property int height: 8
    }
}

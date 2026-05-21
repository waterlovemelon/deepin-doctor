// DTK Button - with proper DTK styling
// Pure QML reimplementation of org.deepin.dtk/Button
import QtQuick 2.15

Item {
    id: button

    property string text: ""
    property bool highlighted: false
    property bool checked: false
    property alias enabled: mouseArea.enabled
    property color textColor: {
        if (checked) return DTKStyle.checkedButton.textNormal
        if (highlighted) return DTKStyle.highlightedButton.textNormal
        return hovered ? DTKStyle.button.textHovered : DTKStyle.button.textNormal
    }

    signal clicked()

    property bool hovered: mouseArea.containsMouse
    property bool pressed: mouseArea.pressed

    implicitWidth: Math.max(DTKStyle.button.width, label.implicitWidth + DTKStyle.button.hPadding * 2)
    implicitHeight: DTKStyle.button.height

    // Drop shadow (behind background)
    Rectangle {
        anchors.fill: bg
        anchors.margins: -1
        radius: bg.radius + 1
        color: "transparent"
        border.color: {
            if (checked) return DTKStyle.checkedButton.dropShadow
            if (highlighted) return DTKStyle.highlightedButton.dropShadow
            return button.hovered ? DTKStyle.button.dropShadowHovered : DTKStyle.button.dropShadow
        }
        border.width: 1
        visible: !button.pressed

        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    // Background
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: DTKStyle.control.radius
        border.width: 1
        border.color: {
            if (checked || highlighted) return DTKStyle.highlightedButton.border
            return button.hovered ? DTKStyle.button.outsideBorderHovered : DTKStyle.button.outsideBorder
        }
        color: {
            if (checked) {
                return button.pressed ? DTKStyle.checkedButton.bgPressed
                       : button.hovered ? DTKStyle.checkedButton.bgHovered
                       : DTKStyle.checkedButton.bgNormal
            }
            if (highlighted) {
                return button.pressed ? DTKStyle.highlightedButton.bgPressed
                       : button.hovered ? DTKStyle.highlightedButton.bgHovered
                       : DTKStyle.highlightedButton.bgNormal
            }
            return button.pressed ? DTKStyle.button.bgPressed
                   : button.hovered ? DTKStyle.button.bgHovered
                   : DTKStyle.button.bgNormal
        }

        // Inner highlight (top edge light)
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: button.pressed ? DTKStyle.button.insideBorderPressed
                   : button.hovered ? DTKStyle.button.insideBorderHovered
                   : DTKStyle.button.insideBorder
            visible: !checked && !highlighted

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: button.text
        font.pixelSize: 13
        font.bold: true
        color: button.enabled ? button.textColor : Qt.rgba(0, 0, 0, 0.3)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }

    opacity: enabled ? 1.0 : 0.4
}

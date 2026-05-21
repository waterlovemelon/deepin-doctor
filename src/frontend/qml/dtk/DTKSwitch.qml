// DTK Switch - toggle control with animated track and handle
// Pure QML reimplementation of org.deepin.dtk/Switch
import QtQuick 2.15

Item {
    id: control

    property bool checked: false
    property bool enabled: true

    signal clicked()
    signal toggled()

    implicitWidth: DTKStyle.switchControl.indicatorWidth
    implicitHeight: DTKStyle.switchControl.indicatorHeight

    opacity: enabled ? 1.0 : 0.4

    // Track
    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: control.checked ? DTKStyle.switchControl.bgOn : DTKStyle.switchControl.bgOff

        Behavior on color { ColorAnimation { duration: 120 } }

        // Inner shadow (top edge highlight)
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            radius: 1
            color: Qt.rgba(1, 1, 1, 0.1)
            visible: !control.checked
        }
    }

    // Handle
    Rectangle {
        id: handle
        width: DTKStyle.switchControl.handleWidth
        height: DTKStyle.switchControl.handleHeight
        radius: DTKStyle.switchControl.handleRadius
        anchors.verticalCenter: track.verticalCenter
        x: control.checked ? track.width - width - 2 : 2
        color: control.checked ? DTKStyle.switchControl.handleOn : DTKStyle.switchControl.handleOff

        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 120 } }

        // Drop shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: parent.radius + 1
            color: "transparent"
            border.color: Qt.rgba(0, 0, 0, 0.05)
            border.width: 1
            z: -1
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: control.enabled
        onClicked: {
            control.checked = !control.checked
            control.toggled()
            control.clicked()
        }
    }
}

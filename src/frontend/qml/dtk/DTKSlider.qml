// DTK Slider - value slider with DTK styling
// Pure QML reimplementation extending QtQuick.Controls Slider
import QtQuick 2.11
import QtQuick.Controls 2.4 as Controls

Controls.Slider {
    id: control

    implicitWidth: DTKStyle.slider.width
    implicitHeight: DTKStyle.slider.height
    opacity: enabled ? 1.0 : 0.4

    // Groove (background track)
    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: control.availableWidth
        height: DTKStyle.slider.groove.height
        radius: height / 2
        color: DTKStyle.slider.groove.background

        // Filled portion
        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: height / 2
            color: DTKStyle.highlightColor

            Behavior on width {
                NumberAnimation { duration: 80 }
            }
        }
    }

    // Handle (thumb)
    handle: Item {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight - height) / 2
        width: DTKStyle.slider.handle.width
        height: DTKStyle.slider.handle.height

        // Handle circle
        Rectangle {
            anchors.centerIn: parent
            width: 16
            height: 16
            radius: 8
            color: "#ffffff"
            border.color: control.pressed ? DTKStyle.highlightColor
                          : control.hovered ? Qt.rgba(0, 0, 0, 0.3)
                          : Qt.rgba(0, 0, 0, 0.15)
            border.width: 1

            // Drop shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                radius: parent.radius + 2
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.05)
                border.width: 1
                z: -1
            }
        }
    }
}

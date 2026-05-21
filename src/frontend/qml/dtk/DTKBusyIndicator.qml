// DTK BusyIndicator - animated loading spinner
// Pure QML reimplementation of org.deepin.dtk/BusyIndicator
import QtQuick 2.11

Item {
    id: control

    property bool running: true
    property int size: DTKStyle.busyIndicator.size
    property color color: DTKStyle.busyIndicator.fillColor
    property int animationDuration: DTKStyle.busyIndicator.animationDuration

    implicitWidth: size
    implicitHeight: size
    visible: running

    // Spinner arc
    Item {
        id: spinner
        anchors.fill: parent

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: control.animationDuration
            loops: Animation.Infinite
            running: control.running
        }

        // Arc using two overlapping rectangles with clip
        Repeater {
            model: 2

            Rectangle {
                width: parent.width
                height: parent.height / 2
                y: index === 0 ? 0 : parent.height / 2
                color: "transparent"

                Rectangle {
                    width: parent.width / 2
                    height: parent.height
                    x: index === 0 ? 0 : parent.width / 2
                    color: "transparent"

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.color: control.color
                        border.width: Math.max(2, control.size / 8)
                        opacity: index === 0 ? 1.0 : 0.4
                    }
                }
            }
        }
    }

    // Simpler alternative: rotating dots
    Repeater {
        model: 8
        active: control.running

        Rectangle {
            width: Math.max(2, control.size / 8)
            height: width
            radius: width / 2
            color: control.color
            opacity: 1.0 - (index * 0.1)

            property real angle: index * (360 / 8)
            x: control.size / 2 + (control.size / 2 - width) * Math.cos(angle * Math.PI / 180) - width / 2
            y: control.size / 2 + (control.size / 2 - height) * Math.sin(angle * Math.PI / 180) - height / 2

            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: control.animationDuration
                loops: Animation.Infinite
                running: control.running
            }
        }
    }
}

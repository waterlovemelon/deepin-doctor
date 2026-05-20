// DTK ProgressBar - pure QML reimplementation of org.deepin.dtk ProgressBar
import QtQuick 2.15

Item {
    id: control

    property real from: 0
    property real to: 1
    property real value: 0
    property real visualPosition: (value - from) / (to - from)

    implicitWidth: DTKStyle.progressBar.width
    implicitHeight: DTKStyle.progressBar.height

    // Background track
    Rectangle {
        anchors.fill: parent
        radius: DTKStyle.progressBar.radius
        color: DTKStyle.progressBar.background
    }

    // Fill bar
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * Math.max(0, Math.min(1, control.visualPosition))
        radius: DTKStyle.progressBar.radius
        color: DTKStyle.progressBar.fill

        Behavior on width {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }
}

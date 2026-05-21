// DTK ProgressBar - pure QML reimplementation of org.deepin.dtk ProgressBar
import QtQuick 2.15

Item {
    id: control

    property real from: 0
    property real to: 1
    property real value: 0
    property real visualPosition: (value - from) / (to - from)
    property string formatText: ""
    property bool indeterminate: false
    property bool animationStop: false

    implicitWidth: DTKStyle.progressBar.width
    implicitHeight: DTKStyle.progressBar.height

    // Background track
    Rectangle {
        anchors.fill: parent
        radius: DTKStyle.progressBar.radius
        color: DTKStyle.progressBar.background
    }

    // Indeterminate mode: animated sliding block
    Item {
        anchors.fill: parent
        visible: control.indeterminate && !control.animationStop
        clip: true

        Rectangle {
            width: DTKStyle.progressBar.indeterminateWidth
            height: parent.height
            radius: DTKStyle.progressBar.radius
            color: DTKStyle.progressBar.fill

            NumberAnimation on x {
                from: -width
                to: control.width
                duration: DTKStyle.progressBar.indeterminateDuration
                loops: Animation.Infinite
                running: control.indeterminate && !control.animationStop
            }
        }
    }

    // Determinate fill bar
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * Math.max(0, Math.min(1, control.visualPosition))
        radius: DTKStyle.progressBar.radius
        color: DTKStyle.progressBar.fill
        visible: !control.indeterminate

        Behavior on width {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }

    // Format text overlay
    Text {
        anchors.centerIn: parent
        text: control.formatText.arg(Math.round(control.visualPosition * 100))
        font.pixelSize: 10
        font.bold: true
        color: "#ffffff"
        visible: control.formatText !== "" && !control.indeterminate
    }
}

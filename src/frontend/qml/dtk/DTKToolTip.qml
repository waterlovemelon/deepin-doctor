// DTK ToolTip - tooltip with floating panel style
// Pure QML reimplementation extending QtQuick.Controls ToolTip
import QtQuick 2.11
import QtQuick.Controls 2.4 as Controls

Controls.ToolTip {
    id: control

    property int radius: 8

    contentItem: Text {
        text: control.text
        font.pixelSize: 12
        color: Qt.rgba(0, 0, 0, 0.7)
    }

    background: Rectangle {
        radius: control.radius
        color: DTKStyle.floatingPanel.background
        border.color: DTKStyle.floatingPanel.outsideBorder
        border.width: 1

        // Inner highlight
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            radius: 1
            color: Qt.rgba(1, 1, 1, 0.1)
        }
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 80 }
    }
}

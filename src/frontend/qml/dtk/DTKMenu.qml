// DTK Menu - context menu with rounded styling
// Pure QML reimplementation extending QtQuick.Controls Menu
import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls

Controls.Menu {
    id: control

    property int radius: DTKStyle.menu.radius

    topPadding: DTKStyle.menu.padding
    bottomPadding: DTKStyle.menu.padding

    background: Rectangle {
        radius: control.radius
        color: DTKStyle.menu.background
        border.color: Qt.rgba(0, 0, 0, 0.08)
        border.width: 1

        // Slight blur effect via opacity
        opacity: 0.95
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
        NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 120 }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 80 }
    }
}

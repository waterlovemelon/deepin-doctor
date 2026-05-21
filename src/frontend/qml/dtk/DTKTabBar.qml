// DTK TabBar - segmented tab selector with DTK styling
// Pure QML reimplementation of tab switching, matching Deepin Toolkit visual language
import QtQuick 2.11
import QtQuick.Layouts 1.11

Item {
    id: tabBar

    // Public API
    // model: list of strings OR list of {label, value} objects
    property var model: []
    property int currentIndex: 0
    readonly property string currentValue: {
        if (currentIndex < 0 || currentIndex >= model.length) return ""
        var item = model[currentIndex]
        return (typeof item === "object") ? (item.value || item.label || "") : item
    }

    signal tabClicked(int index)

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: 36

    onCurrentIndexChanged: {
        if (currentIndex < 0) currentIndex = 0
        if (currentIndex >= model.length) currentIndex = model.length - 1
    }

    RowLayout {
        id: rowLayout
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: tabBar.model

            delegate: Item {
                Layout.preferredWidth: tabLabel.implicitWidth + 24
                Layout.preferredHeight: 32

                property bool isActive: tabBar.currentIndex === index
                property string tabLabel: (typeof modelData === "object") ? (modelData.label || "") : modelData

                Rectangle {
                    anchors.fill: parent
                    radius: DTKStyle.control.radius
                    color: parent.isActive ? Qt.rgba(DTKStyle.highlightColor.r, DTKStyle.highlightColor.g, DTKStyle.highlightColor.b, 0.1)
                           : tabMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.05)
                           : "transparent"
                }

                Text {
                    id: tabLabel
                    anchors.centerIn: parent
                    text: parent.tabLabel
                    font.pixelSize: 13
                    font.bold: parent.isActive
                    color: parent.isActive ? DTKStyle.highlightColor : Qt.rgba(0, 0, 0, 0.5)

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tabBar.currentIndex = index
                        tabBar.tabClicked(index)
                    }
                }
            }
        }
    }
}

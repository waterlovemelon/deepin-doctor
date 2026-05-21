import QtQuick 2.11
import QtQuick.Layouts 1.11
import "../dtk"

Item {
    id: root

    property string activeModule: ""
    property var modules: []

    signal moduleClicked(string moduleId)

    function getIconBgColor(colorName) {
        var map = {
            "red": "#ffebee",
            "blue": "#e8f0fe",
            "green": "#e8f5e9",
            "orange": "#fff3e0",
            "purple": "#f3e5f5",
            "teal": "#e0f2f1",
            "indigo": "#e8eaf6",
            "brown": "#efebe9"
        }
        return map[colorName] || "#f5f5f5"
    }

    ListView {
        id: listView
        anchors.fill: parent
        clip: true
        spacing: 4
        model: modules

        delegate: DTKItemDelegate {
            width: listView.width
            height: 56
            checked: modelData.id === root.activeModule

            contentItem: RowLayout {
                spacing: DTKStyle.control.spacing

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.leftMargin: DTKStyle.control.padding
                    radius: DTKStyle.control.radius
                    color: checked ? Qt.rgba(1, 1, 1, 0.2) : getIconBgColor(modelData.color)

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon || ""
                        font.pixelSize: 18
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 12
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.rightMargin: DTKStyle.control.padding
                    spacing: 2

                    Text {
                        text: modelData.name || modelData.id || ""
                        font.pixelSize: 13
                        font.bold: true
                        color: checked ? DTKStyle.itemDelegate.checkedText : DTKStyle.itemDelegate.hoveredText
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: modelData.desc || ""
                        font.pixelSize: 11
                        color: checked ? Qt.rgba(1, 1, 1, 0.7) : Qt.rgba(0, 0, 0, 0.4)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: text !== ""
                    }
                }
            }

            onClicked: {
                root.activeModule = modelData.id
                root.moduleClicked(modelData.id)
            }
        }
    }
}

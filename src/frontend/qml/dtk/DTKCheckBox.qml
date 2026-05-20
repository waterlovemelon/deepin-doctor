// DTK CheckBox - pure QML reimplementation of org.deepin.dtk CheckBox
import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: control

    property string text: ""
    property bool checked: false
    property bool enabled: true
    property int spacing: DTKStyle.control.spacing

    signal clicked()
    signal toggled()

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Math.max(DTKStyle.checkBox.indicatorHeight, label.implicitHeight) + DTKStyle.checkBox.padding * 2

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: control.spacing

        // Indicator
        Rectangle {
            Layout.preferredWidth: DTKStyle.checkBox.indicatorWidth
            Layout.preferredHeight: DTKStyle.checkBox.indicatorHeight
            Layout.alignment: Qt.AlignVCenter
            radius: DTKStyle.checkBox.focusRadius
            color: control.checked ? DTKStyle.highlightColor : "transparent"
            border.color: control.checked ? DTKStyle.highlightColor : Qt.rgba(0, 0, 0, 0.3)
            border.width: control.checked ? 0 : 1.5

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            // Checkmark
            Text {
                anchors.centerIn: parent
                text: "✓"
                color: "#ffffff"
                font.pixelSize: 11
                font.bold: true
                visible: control.checked
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

        // Label
        Text {
            id: label
            text: control.text
            font.pixelSize: 13
            color: control.enabled ? Qt.rgba(0, 0, 0, 0.7) : Qt.rgba(0, 0, 0, 0.3)
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight

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
    }
}

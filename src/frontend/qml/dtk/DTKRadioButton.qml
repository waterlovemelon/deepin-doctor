// DTK RadioButton - radio selection control
// Pure QML reimplementation of org.deepin.dtk/RadioButton
import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: control

    property string text: ""
    property bool checked: false
    property bool enabled: true
    property int spacing: DTKStyle.radioButton.spacing
    property string groupName: ""

    signal clicked()
    signal toggled()

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Math.max(DTKStyle.radioButton.indicatorSize, label.implicitHeight)
                     + DTKStyle.radioButton.topPadding + DTKStyle.radioButton.bottomPadding

    opacity: enabled ? 1.0 : 0.4

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: control.spacing

        // Indicator (circle)
        Item {
            Layout.preferredWidth: DTKStyle.radioButton.indicatorSize
            Layout.preferredHeight: DTKStyle.radioButton.indicatorSize
            Layout.alignment: Qt.AlignVCenter

            // Outer circle
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: control.checked ? DTKStyle.highlightColor : Qt.rgba(0, 0, 0, 0.3)
                border.width: control.checked ? 0 : 1.5

                Behavior on border.color { ColorAnimation { duration: 120 } }

                // Inner filled circle (when checked)
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.55
                    height: parent.height * 0.55
                    radius: width / 2
                    color: DTKStyle.highlightColor
                    visible: control.checked

                    Behavior on visible {
                        NumberAnimation { duration: 120 }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                enabled: control.enabled
                onClicked: {
                    if (!control.checked) {
                        control.checked = true
                        control.toggled()
                    }
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
                    if (!control.checked) {
                        control.checked = true
                        control.toggled()
                    }
                    control.clicked()
                }
            }
        }
    }
}

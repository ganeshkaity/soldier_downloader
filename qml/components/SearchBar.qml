import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property alias text: textInput.text
    property string placeholder: "Paste YouTube URL or search YouTube..."
    property bool showPasteButton: true

    signal accepted(string query)
    signal searchClicked(string query)

    implicitHeight: 50
    radius: Theme.radiusLarge
    color: Theme.glassInput
    border.color: textInput.activeFocus ? Theme.accent : Theme.borderCard
    border.width: textInput.activeFocus ? 2 : 1

    Behavior on border.color { ColorAnimation { duration: 150 } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 8
        spacing: 12

        // Search/Link Icon
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "🔍"
            font.pixelSize: 16
            opacity: 0.6
        }

        // Text Input
        TextInput {
            id: textInput
            width: parent.width - 16 - 12 - (pasteBtn.visible ? pasteBtn.width + 8 : 0) - (clearBtn.visible ? clearBtn.width + 8 : 0) - 24
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSubheading
            selectByMouse: true
            selectionColor: Theme.accent
            selectedTextColor: Theme.textOnAccent
            verticalAlignment: TextInput.AlignVCenter

            Text {
                text: root.placeholder
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSubheading
                visible: !textInput.text && !textInput.activeFocus
                anchors.verticalCenter: parent.verticalCenter
            }

            onAccepted: {
                if (text.trim() !== "") {
                    root.accepted(text.trim());
                }
            }
        }

        // Clear button
        Item {
            id: clearBtn
            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            visible: textInput.text.length > 0

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: clearMouse.containsMouse ? Theme.glassHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                }
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    textInput.text = "";
                    textInput.forceActiveFocus();
                }
            }
        }

        // Paste button
        Item {
            id: pasteBtn
            width: 64
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showPasteButton && textInput.text.length === 0

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSmall
                color: pasteMouse.containsMouse ? Theme.glassHover : Theme.glassCard
                border.color: Theme.borderSubtle
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Paste"
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }
            }

            MouseArea {
                id: pasteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    textInput.paste();
                    if (textInput.text.trim() !== "") {
                        root.accepted(textInput.text.trim());
                    }
                }
            }
        }
    }
}

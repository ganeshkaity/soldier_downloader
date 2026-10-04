import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string text: "Button"
    property string iconText: ""
    property string variant: "primary" // "primary" | "secondary" | "tertiary" | "destructive"
    property bool disabled: false
    property int buttonHeight: 40
    property int customRadius: Theme.radiusMedium

    signal clicked()

    implicitWidth: Math.max(buttonLayout.implicitWidth + 32, 80)
    implicitHeight: buttonHeight
    opacity: disabled ? 0.45 : 1.0

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: root.customRadius
        antialiasing: true

        // Background color logic based on variant
        color: {
            if (root.variant === "primary") {
                return mouseArea.containsPress ? Theme.accentPressed :
                       mouseArea.containsMouse ? Theme.accentHover : Theme.accent;
            } else if (root.variant === "destructive") {
                return mouseArea.containsPress ? "#b91c1c" :
                       mouseArea.containsMouse ? "#dc2626" : "#7f1d1d44";
            } else if (root.variant === "secondary") {
                return mouseArea.containsPress ? Theme.glassActive :
                       mouseArea.containsMouse ? Theme.glassHover : Theme.glassCard;
            } else { // tertiary
                return mouseArea.containsPress ? Theme.glassActive :
                       mouseArea.containsMouse ? Theme.glassHover : "transparent";
            }
        }

        border.color: {
            if (root.variant === "primary") {
                return "transparent";
            } else if (root.variant === "destructive") {
                return mouseArea.containsMouse ? "#ef4444" : "#991b1b";
            } else if (root.variant === "secondary") {
                return mouseArea.containsMouse ? Theme.accent : Theme.borderCard;
            } else {
                return mouseArea.containsMouse ? Theme.borderSubtle : "transparent";
            }
        }
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Row {
            id: buttonLayout
            anchors.centerIn: parent
            spacing: 8

            Text {
                id: iconLabel
                visible: root.iconText !== ""
                text: root.iconText
                font.pixelSize: Theme.fontSizeHeading
                anchors.verticalCenter: parent.verticalCenter
                color: root.variant === "primary" ? Theme.textOnAccent : Theme.textPrimary
            }

            Text {
                id: textLabel
                text: root.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBody
                font.weight: root.variant === "primary" ? Font.DemiBold : Font.Medium
                anchors.verticalCenter: parent.verticalCenter
                color: root.variant === "primary" ? Theme.textOnAccent : 
                       root.variant === "destructive" ? (mouseArea.containsMouse ? "#ffffff" : "#fca5a5") : 
                       Theme.textPrimary
            }
        }

        scale: mouseArea.containsPress ? 0.98 : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: !root.disabled
        hoverEnabled: true
        cursorShape: root.disabled ? Qt.ForbiddenCursor : Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

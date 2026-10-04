import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string iconText: "📥"
    property string title: "No items found"
    property string description: "Nothing to display at the moment."
    property string buttonText: ""
    
    signal actionClicked()

    implicitWidth: 400
    implicitHeight: 260

    Column {
        anchors.centerIn: parent
        spacing: 16
        width: Math.min(parent.width - 40, 420)

        // Circular icon container
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 72
            height: 72
            radius: 36
            color: Theme.glassCard
            border.color: Theme.borderSubtle
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: root.iconText
                font.pixelSize: 32
            }
        }

        // Title
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeHeading
            font.weight: Font.DemiBold
            color: Theme.textPrimary
            horizontalAlignment: Text.AlignHCenter
        }

        // Description
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.description
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeBody
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            width: parent.width
        }

        // Optional Action Button
        GlassButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.buttonText !== ""
            text: root.buttonText
            variant: "secondary"
            onClicked: root.actionClicked()
        }
    }
}

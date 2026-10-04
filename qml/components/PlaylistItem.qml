import QtQuick
import QtQuick.Controls

GlassCard {
    id: root

    property int itemIndex: 1
    property string title: ""
    property string durationStr: ""
    property string thumbnailUrl: ""
    property string channel: ""
    property bool isSelected: false

    signal toggled(bool selected)

    implicitHeight: 64
    cardColor: isSelected ? "#20324e" : (isHovered ? Theme.glassHover : Theme.glassCardTranslucent)
    borderColor: isSelected ? Theme.accent : Theme.borderCard
    interactive: true
    onClicked: {
        root.isSelected = !root.isSelected;
        root.toggled(root.isSelected);
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 16
        spacing: 12

        // Custom checkbox
        Rectangle {
            width: 22
            height: 22
            radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: root.isSelected ? Theme.accent : "transparent"
            border.color: root.isSelected ? Theme.accent : Theme.borderSubtle
            border.width: 1.5

            Text {
                anchors.centerIn: parent
                text: "✓"
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Theme.textOnAccent
                visible: root.isSelected
            }
        }

        // Index
        Text {
            width: 28
            anchors.verticalCenter: parent.verticalCenter
            text: root.itemIndex < 10 ? "0" + root.itemIndex : "" + root.itemIndex
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignRight
        }

        // Thumbnail
        Rectangle {
            width: 68
            height: 42
            radius: 6
            color: "#080c14"
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            Image {
                anchors.fill: parent
                source: root.thumbnailUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        // Title and channel
        Column {
            width: parent.width - 22 - 28 - 68 - 70 - 48
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.title
                width: parent.width
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBody
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                text: root.channel
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTiny
                elide: Text.ElideRight
            }
        }

        // Duration
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.durationStr
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            horizontalAlignment: Text.AlignRight
            width: 50
        }
    }
}

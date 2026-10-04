import QtQuick
import QtQuick.Controls

GlassCard {
    id: root

    property string videoId: ""
    property string title: ""
    property string channel: ""
    property string durationStr: ""
    property string thumbnailUrl: ""
    property string viewCountStr: ""
    property string uploadDate: ""
    property string url: ""
    property string actionText: "Configure"

    signal selected()
    signal copyUrlRequested()

    implicitHeight: 110
    cardColor: isHovered ? Theme.glassHover : Theme.glassCardTranslucent
    interactive: true
    onClicked: root.selected()

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16

        // Thumbnail with Duration Overlay
        Item {
            width: 140
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusMedium
                color: "#080c14"
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.thumbnailUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                // Duration badge
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    height: 18
                    width: durationLabel.implicitWidth + 8
                    radius: 4
                    color: "#d0000000"
                    visible: root.durationStr !== ""

                    Text {
                        id: durationLabel
                        anchors.centerIn: parent
                        text: root.durationStr
                        color: "#ffffff"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTiny
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        // Details
        Column {
            width: parent.width - 140 - 16 - actionsRow.width - 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: root.title
                width: parent.width
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSubheading
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
            }

            Text {
                text: root.channel
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
            }

            Row {
                spacing: 12
                visible: root.viewCountStr !== "" || root.uploadDate !== ""

                Text {
                    text: root.viewCountStr !== "" ? root.viewCountStr + " views" : ""
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    visible: root.viewCountStr !== ""
                }

                Text {
                    text: "•"
                    color: Theme.textMuted
                    font.pixelSize: Theme.fontSizeSmall
                    visible: root.viewCountStr !== "" && root.uploadDate !== ""
                }

                Text {
                    text: root.uploadDate
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    visible: root.uploadDate !== ""
                }
            }
        }

        // Action Buttons
        Row {
            id: actionsRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            GlassButton {
                text: "📋"
                variant: "tertiary"
                buttonHeight: 36
                customRadius: Theme.radiusSmall
                implicitWidth: 36
                onClicked: root.copyUrlRequested()
            }

            GlassButton {
                text: root.actionText
                variant: "primary"
                buttonHeight: 36
                customRadius: Theme.radiusSmall
                onClicked: root.selected()
            }
        }
    }
}

import QtQuick
import QtQuick.Controls

GlassCard {
    id: root

    property string itemId: ""
    property string title: ""
    property string thumbnailUrl: ""
    property string mediaType: "video"
    property string quality: "Best"
    property string outputFormat: "MP4"
    property string status: "Queued"
    property real progressPercent: 0.0
    property string speedStr: "—"
    property string etaStr: "—"
    property string downloadedStr: "0 B"
    property string totalStr: "—"
    property string destinationFile: ""
    property string errorMessage: ""

    signal cancelClicked(string id)
    signal retryClicked(string id)
    signal openFileClicked(string path)
    signal openFolderClicked(string path)
    signal removeClicked(string id)

    implicitHeight: root.errorMessage !== "" ? 125 : 105
    cardColor: Theme.glassCardTranslucent

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        // Thumbnail
        Item {
            width: 100
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

                // Format badge
                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 4
                    height: 16
                    width: badgeText.implicitWidth + 8
                    radius: 3
                    color: root.mediaType === "audio" ? "#804f46e5" : "#800284c7"

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.outputFormat.toUpperCase()
                        color: "#ffffff"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }
            }
        }

        // Details and Progress
        Column {
            width: parent.width - 100 - 14 - actionButtons.width - 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Title and Quality badge
            Row {
                width: parent.width
                spacing: 8

                Text {
                    width: parent.width - qualityBadge.width - 8
                    text: root.title
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBody
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: qualityBadge
                    height: 18
                    width: qualityText.implicitWidth + 8
                    radius: 4
                    color: Theme.glassCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    Text {
                        id: qualityText
                        anchors.centerIn: parent
                        text: root.quality
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTiny
                        font.weight: Font.Medium
                    }
                }
            }

            // Progress Bar (when downloading or processing)
            GlassProgressBar {
                width: parent.width
                value: root.progressPercent
                visible: root.status !== "Completed" && root.status !== "Failed" && root.status !== "Cancelled"
                barHeight: 6
            }

            // Status, Speed, ETA, Size row
            Row {
                width: parent.width
                spacing: 12

                // Status Pill
                Rectangle {
                    height: 18
                    width: statusText.implicitWidth + 12
                    radius: 9
                    color: {
                        if (root.status === "Completed") return "#102216";
                        if (root.status === "Failed") return "#281010";
                        if (root.status === "Cancelled") return "#1a1e26";
                        if (root.status === "Downloading") return "#0c2338";
                        return Theme.glassCard;
                    }
                    border.color: {
                        if (root.status === "Completed") return Theme.statusSuccess;
                        if (root.status === "Failed") return Theme.statusError;
                        if (root.status === "Cancelled") return Theme.textMuted;
                        if (root.status === "Downloading") return Theme.accent;
                        return Theme.borderSubtle;
                    }
                    border.width: 1

                    Text {
                        id: statusText
                        anchors.centerIn: parent
                        text: root.status
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTiny
                        font.weight: Font.Medium
                        color: {
                            if (root.status === "Completed") return Theme.statusSuccess;
                            if (root.status === "Failed") return Theme.statusError;
                            if (root.status === "Cancelled") return Theme.textMuted;
                            if (root.status === "Downloading") return Theme.accent;
                            return Theme.textSecondary;
                        }
                    }
                }

                // Percentage
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.progressPercent) + "%"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    visible: root.status === "Downloading" || root.status === "Merging" || root.status === "Converting"
                }

                // Speed
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.speedStr
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    visible: root.status === "Downloading" && root.speedStr !== "—"
                }

                // ETA
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ETA " + root.etaStr
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    visible: root.status === "Downloading" && root.etaStr !== "—"
                }

                // Downloaded / Total
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.downloadedStr + (root.totalStr !== "—" ? " / " + root.totalStr : "")
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    visible: root.downloadedStr !== "0 B"
                }
            }

            // Error message display if failed
            Text {
                width: parent.width
                text: "Reason: " + root.errorMessage
                color: Theme.statusError
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                visible: root.errorMessage !== ""
            }
        }

        // Action Buttons
        Row {
            id: actionButtons
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Open File (when completed)
            GlassButton {
                visible: root.status === "Completed" && root.destinationFile !== ""
                text: "Open"
                variant: "primary"
                buttonHeight: 32
                customRadius: Theme.radiusSmall
                onClicked: root.openFileClicked(root.destinationFile)
            }

            // Open Folder (when completed)
            GlassButton {
                visible: root.status === "Completed" && root.destinationFile !== ""
                text: "📁"
                variant: "secondary"
                buttonHeight: 32
                customRadius: Theme.radiusSmall
                implicitWidth: 32
                onClicked: root.openFolderClicked(root.destinationFile)
            }

            // Retry button (when failed or cancelled)
            GlassButton {
                visible: root.status === "Failed" || root.status === "Cancelled"
                text: "Retry"
                variant: "secondary"
                buttonHeight: 32
                customRadius: Theme.radiusSmall
                onClicked: root.retryClicked(root.itemId)
            }

            // Cancel button (when active or queued)
            GlassButton {
                visible: root.status === "Queued" || root.status === "Preparing" || root.status === "Downloading" || root.status === "Merging" || root.status === "Converting"
                text: "Cancel"
                variant: "tertiary"
                buttonHeight: 32
                customRadius: Theme.radiusSmall
                onClicked: root.cancelClicked(root.itemId)
            }

            // Remove button
            GlassButton {
                text: "✕"
                variant: "tertiary"
                buttonHeight: 32
                customRadius: Theme.radiusSmall
                implicitWidth: 32
                onClicked: root.removeClicked(root.itemId)
            }
        }
    }
}

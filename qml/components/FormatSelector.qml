import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string mediaMode: "video" // "video" | "audio"
    property string videoQuality: "Best"
    property string videoContainer: "MP4"
    property string audioFormat: "MP3"
    property bool showAdvancedButton: true

    signal advancedFormatsClicked()

    implicitWidth: 500
    implicitHeight: selectorColumn.implicitHeight

    readonly property var qualityPresets: ["Best", "2160p", "1440p", "1080p", "720p", "480p", "360p"]
    readonly property var containers: ["MP4", "MKV", "WebM"]
    readonly property var audioFormats: ["Best Audio", "MP3", "M4A", "FLAC", "OPUS", "WAV", "AAC"]

    Column {
        id: selectorColumn
        width: parent.width
        spacing: 16

        // Mode Switcher (Video vs Audio)
        Row {
            spacing: 8

            Rectangle {
                width: 120
                height: 36
                radius: Theme.radiusMedium
                color: root.mediaMode === "video" ? Theme.accent : Theme.glassCard
                border.color: root.mediaMode === "video" ? Theme.accent : Theme.borderCard
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "🎬"; font.pixelSize: 13 }
                    Text {
                        text: "Video"
                        color: root.mediaMode === "video" ? Theme.textOnAccent : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeBody
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mediaMode = "video"
                }
            }

            Rectangle {
                width: 120
                height: 36
                radius: Theme.radiusMedium
                color: root.mediaMode === "audio" ? Theme.accent : Theme.glassCard
                border.color: root.mediaMode === "audio" ? Theme.accent : Theme.borderCard
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "🎵"; font.pixelSize: 13 }
                    Text {
                        text: "Audio"
                        color: root.mediaMode === "audio" ? Theme.textOnAccent : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeBody
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mediaMode = "audio"
                }
            }
        }

        // Video Settings
        Column {
            width: parent.width
            spacing: 12
            visible: root.mediaMode === "video"

            Text {
                text: "Resolution Quality"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            // Quality Presets Flow
            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.qualityPresets

                    Rectangle {
                        width: qualityLabel.implicitWidth + 24
                        height: 32
                        radius: Theme.radiusSmall
                        color: root.videoQuality === modelData ? Theme.glassActive : Theme.glassCard
                        border.color: root.videoQuality === modelData ? Theme.accent : Theme.borderSubtle
                        border.width: 1

                        Text {
                            id: qualityLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: root.videoQuality === modelData ? Theme.accent : Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: root.videoQuality === modelData ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.videoQuality = modelData
                        }
                    }
                }

                // Advanced Button
                GlassButton {
                    visible: root.showAdvancedButton
                    text: "Available Formats..."
                    variant: "tertiary"
                    buttonHeight: 32
                    customRadius: Theme.radiusSmall
                    onClicked: root.advancedFormatsClicked()
                }
            }

            // Container Selection
            Row {
                spacing: 12
                topPadding: 4

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Container:"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }

                Repeater {
                    model: root.containers

                    Rectangle {
                        width: 60
                        height: 28
                        radius: Theme.radiusSmall
                        color: root.videoContainer === modelData ? Theme.glassActive : Theme.glassCard
                        border.color: root.videoContainer === modelData ? Theme.accent : Theme.borderSubtle
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: root.videoContainer === modelData ? Theme.accent : Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: root.videoContainer === modelData ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.videoContainer = modelData
                        }
                    }
                }
            }
        }

        // Audio Settings
        Column {
            width: parent.width
            spacing: 12
            visible: root.mediaMode === "audio"

            Text {
                text: "Audio Output Format"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            // Audio Formats Flow
            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.audioFormats

                    Rectangle {
                        width: audioLabel.implicitWidth + 24
                        height: 32
                        radius: Theme.radiusSmall
                        color: root.audioFormat === modelData ? Theme.glassActive : Theme.glassCard
                        border.color: root.audioFormat === modelData ? Theme.accent : Theme.borderSubtle
                        border.width: 1

                        Text {
                            id: audioLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: root.audioFormat === modelData ? Theme.accent : Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: root.audioFormat === modelData ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.audioFormat = modelData
                        }
                    }
                }
            }

            Text {
                text: "ℹ Artwork from thumbnail will be embedded automatically. FFmpeg will transcode if necessary."
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTiny
            }
        }
    }
}

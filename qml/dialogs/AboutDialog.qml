import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    property bool isVisible: false

    anchors.fill: parent
    visible: opacity > 0
    opacity: isVisible ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgOverlay
        MouseArea { anchors.fill: parent; onClicked: root.isVisible = false }
    }

    GlassCard {
        width: Math.min(parent.width - 40, 520)
        height: aboutContent.implicitHeight + 48
        anchors.centerIn: parent
        cardColor: Theme.bgPanel
        borderColor: Theme.borderHighlight

        Column {
            id: aboutContent
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            Item {
                width: parent.width
                height: 52

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    Rectangle {
                        width: 52
                        height: 52
                        radius: 26
                        color: Theme.glassCard
                        border.color: Theme.borderHighlight
                        border.width: 1.5

                        Text {
                            anchors.centerIn: parent
                            text: "🛡️"
                            font.pixelSize: 26
                        }
                    }

                    Column {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: bridge ? bridge.appName : "Soldier Downloader"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeHeading
                            font.weight: Font.Bold
                            color: Theme.textPrimary
                        }

                        Text {
                            text: "Version " + (bridge ? bridge.appVersion : "0.1.0") + " • Windows Desktop"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.accent
                        }
                    }
                }

                GlassButton {
                    text: "✕"
                    variant: "tertiary"
                    buttonHeight: 32
                    implicitWidth: 32
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.isVisible = false
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.borderSubtle }

            Text {
                text: "Soldier Downloader is a high-performance native Windows desktop application for downloading YouTube videos, audio tracks, playlists, and thumbnails locally. Built with zero cloud dependence."
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBody
                wrapMode: Text.WordWrap
                width: parent.width
            }

            // Environment status summary
            GlassCard {
                width: parent.width
                implicitHeight: envColumn.implicitHeight + 20
                cardColor: Theme.glassCardTranslucent

                Column {
                    id: envColumn
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    Text {
                        text: "Environment Status:"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }

                    Row {
                        spacing: 16
                        Text {
                            text: "yt-dlp: " + (bridge && bridge.environment.yt_dlp.available ? "✓ Ready" : "✕ Not Found")
                            color: bridge && bridge.environment.yt_dlp.available ? Theme.statusSuccess : Theme.statusError
                            font.pixelSize: Theme.fontSizeTiny
                        }
                        Text {
                            text: "FFmpeg: " + (bridge && bridge.environment.ffmpeg.available ? "✓ Ready" : "✕ Not Found")
                            color: bridge && bridge.environment.ffmpeg.available ? Theme.statusSuccess : Theme.statusError
                            font.pixelSize: Theme.fontSizeTiny
                        }
                        Text {
                            text: "Cookies: " + (bridge && bridge.environment.cookies_found ? "✓ Loaded" : "Not configured")
                            color: bridge && bridge.environment.cookies_found ? Theme.statusSuccess : Theme.textMuted
                            font.pixelSize: Theme.fontSizeTiny
                        }
                    }
                }
            }

            Text {
                text: "Security Note: cookies.txt may contain private authenticated session information. Soldier Downloader keeps all operations local and never sends cookie data to external servers."
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTiny
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Row {
                anchors.right: parent.right
                spacing: 12
                topPadding: 4

                GlassButton {
                    text: "Open Logs Folder"
                    variant: "secondary"
                    buttonHeight: 36
                    onClicked: {
                        if (bridge) bridge.openLogsFolder();
                    }
                }

                GlassButton {
                    text: "Close"
                    variant: "primary"
                    buttonHeight: 36
                    onClicked: root.isVisible = false
                }
            }
        }
    }

    function openDialog() {
        root.isVisible = true;
    }
}

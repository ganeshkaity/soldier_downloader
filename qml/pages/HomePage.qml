import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root

    signal navigateTo(string pageName)
    signal analyzeRequested(string url)
    signal searchRequested(string query)
    signal thumbnailRequested(string queryOrUrl)
    signal playlistRequested(string url)

    property var analyzedVideo: null
    property bool isAnalyzing: false

    ScrollView {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        clip: true
        contentWidth: availableWidth

        Column {
            width: parent.width
            spacing: 24

            // Top Hero Header
            Column {
                spacing: 8
                width: parent.width

                Row {
                    spacing: 12
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 8
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent
                            text: "🛡️"
                            font.pixelSize: 20
                        }
                    }

                    Text {
                        text: bridge ? bridge.appName : "Soldier Downloader"
                        font.family: Theme.fontFamily
                        font.pixelSize: 28
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    text: "Download YouTube media locally. Fast. Flexible. Simple."
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSubheading
                    color: Theme.textSecondary
                }
            }

            // Primary Search / URL Input Card
            GlassCard {
                width: parent.width
                implicitHeight: inputCardCol.implicitHeight + 36
                cardColor: Theme.glassCardTranslucent

                Column {
                    id: inputCardCol
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 16

                    SearchBar {
                        id: mainSearchInput
                        width: parent.width
                        placeholder: "Paste YouTube URL or search YouTube..."
                        onAccepted: function(query) {
                            handleInput(query, "analyze");
                        }
                    }

                    Row {
                        spacing: 12
                        anchors.right: parent.right

                        GlassButton {
                            text: "Download"
                            variant: "primary"
                            iconText: "⬇"
                            buttonHeight: 40
                            disabled: mainSearchInput.text.trim() === "" || root.isAnalyzing
                            onClicked: handleInput(mainSearchInput.text.trim(), "download")
                        }

                        GlassButton {
                            text: "Analyze"
                            variant: "secondary"
                            iconText: "🔍"
                            buttonHeight: 40
                            disabled: mainSearchInput.text.trim() === "" || root.isAnalyzing
                            onClicked: handleInput(mainSearchInput.text.trim(), "analyze")
                        }

                        GlassButton {
                            text: "Search"
                            variant: "tertiary"
                            buttonHeight: 40
                            disabled: mainSearchInput.text.trim() === "" || root.isAnalyzing
                            onClicked: root.searchRequested(mainSearchInput.text.trim())
                        }
                    }
                }
            }

            // Live Queue Status Counter Strip
            GlassCard {
                width: parent.width
                implicitHeight: 60
                cardColor: Theme.glassCardTranslucent

                Row {
                    anchors.centerIn: parent
                    spacing: 36

                    Row {
                        spacing: 8
                        Text { text: "⬇"; font.pixelSize: 15; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: (bridge ? bridge.activeCount : 0) + " Downloading"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeBody
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle { width: 1; height: 24; color: Theme.borderSubtle; anchors.verticalCenter: parent.verticalCenter }

                    Row {
                        spacing: 8
                        Text { text: "⏳"; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: (bridge ? bridge.queuedCount : 0) + " Queued"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeBody
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle { width: 1; height: 24; color: Theme.borderSubtle; anchors.verticalCenter: parent.verticalCenter }

                    Row {
                        spacing: 8
                        Text { text: "✓"; font.pixelSize: 15; color: Theme.statusSuccess; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: (bridge ? bridge.completedCount : 0) + " Completed"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeBody
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Analysis In Progress Card
            GlassCard {
                width: parent.width
                implicitHeight: 80
                visible: root.isAnalyzing
                cardColor: "#14243b"
                borderColor: Theme.accent

                Row {
                    anchors.centerIn: parent
                    spacing: 16

                    GlassProgressBar {
                        width: 140
                        value: 50
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Analyzing media stream information..."
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeBody
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Analyzed Video Configuration Card
            GlassCard {
                id: analyzedCard
                width: parent.width
                implicitHeight: analyzedCol.implicitHeight + 36
                visible: root.analyzedVideo !== null && !root.isAnalyzing
                cardColor: Theme.glassCardTranslucent
                borderColor: Theme.borderHighlight

                Column {
                    id: analyzedCol
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 16

                    Row {
                        width: parent.width
                        spacing: 16

                        // Thumbnail
                        Rectangle {
                            width: 160
                            height: 90
                            radius: Theme.radiusMedium
                            color: "#080c14"
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: root.analyzedVideo ? root.analyzedVideo.thumbnail_url : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        // Info
                        Column {
                            width: parent.width - 160 - 16
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: root.analyzedVideo ? root.analyzedVideo.title : ""
                                width: parent.width
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeHeading
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                            }

                            Row {
                                spacing: 14
                                Text {
                                    text: root.analyzedVideo ? root.analyzedVideo.channel : ""
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                }
                                Text {
                                    text: "• " + (root.analyzedVideo ? root.analyzedVideo.duration_str : "")
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                                Text {
                                    text: "• " + (root.analyzedVideo && root.analyzedVideo.view_count_str ? root.analyzedVideo.view_count_str + " views" : "")
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    visible: root.analyzedVideo && root.analyzedVideo.view_count_str !== "—"
                                }
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.borderSubtle }

                    // Format and Options
                    FormatSelector {
                        id: homeFormatSelector
                        width: parent.width
                        onAdvancedFormatsClicked: {
                            if (root.analyzedVideo && availableFormatsDialog) {
                                availableFormatsDialog.openWithFormats(root.analyzedVideo.formats);
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        spacing: 12
                        topPadding: 8

                        GlassButton {
                            text: "Dismiss"
                            variant: "tertiary"
                            buttonHeight: 38
                            onClicked: root.analyzedVideo = null
                        }

                        GlassButton {
                            text: "Add to Download Queue"
                            variant: "primary"
                            iconText: "⬇"
                            buttonHeight: 38
                            onClicked: {
                                if (bridge && root.analyzedVideo) {
                                    bridge.queueSingleDownload(
                                        root.analyzedVideo.url,
                                        root.analyzedVideo.video_id,
                                        root.analyzedVideo.title,
                                        root.analyzedVideo.thumbnail_url,
                                        homeFormatSelector.mediaMode,
                                        homeFormatSelector.videoQuality,
                                        homeFormatSelector.mediaMode === "video" ? homeFormatSelector.videoContainer : homeFormatSelector.audioFormat,
                                        "",
                                        ""
                                    );
                                    root.analyzedVideo = null;
                                    mainSearchInput.text = "";
                                }
                            }
                        }
                    }
                }
            }

            // Quick-Action Cards Section
            Text {
                text: "Quick Navigation"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeHeading
                font.weight: Font.DemiBold
                color: Theme.textPrimary
            }

            Grid {
                width: parent.width
                columns: width > 900 ? 5 : (width > 600 ? 3 : 2)
                spacing: 14

                // Video
                GlassCard {
                    width: (parent.width - (parent.spacing * (parent.columns - 1))) / parent.columns
                    implicitHeight: 120
                    interactive: true
                    onClicked: root.navigateTo("search")

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "🎬"; font.pixelSize: 26; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Video"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeBody; font.weight: Font.DemiBold; color: Theme.textPrimary; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Download single video"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTiny; color: Theme.textMuted; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }

                // Audio
                GlassCard {
                    width: (parent.width - (parent.spacing * (parent.columns - 1))) / parent.columns
                    implicitHeight: 120
                    interactive: true
                    onClicked: {
                        homeFormatSelector.mediaMode = "audio";
                        mainSearchInput.forceActiveFocus();
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "🎵"; font.pixelSize: 26; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Audio"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeBody; font.weight: Font.DemiBold; color: Theme.textPrimary; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Extract MP3/M4A/FLAC"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTiny; color: Theme.textMuted; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }

                // Playlist
                GlassCard {
                    width: (parent.width - (parent.spacing * (parent.columns - 1))) / parent.columns
                    implicitHeight: 120
                    interactive: true
                    onClicked: root.navigateTo("playlist")

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "📑"; font.pixelSize: 26; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Playlist"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeBody; font.weight: Font.DemiBold; color: Theme.textPrimary; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Batch download playlist"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTiny; color: Theme.textMuted; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }

                // Batch
                GlassCard {
                    width: (parent.width - (parent.spacing * (parent.columns - 1))) / parent.columns
                    implicitHeight: 120
                    interactive: true
                    onClicked: root.navigateTo("batch")

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "📦"; font.pixelSize: 26; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Batch & TXT"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeBody; font.weight: Font.DemiBold; color: Theme.textPrimary; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Multi-line & file import"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTiny; color: Theme.textMuted; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }

                // Thumbnail
                GlassCard {
                    width: (parent.width - (parent.spacing * (parent.columns - 1))) / parent.columns
                    implicitHeight: 120
                    interactive: true
                    onClicked: root.navigateTo("thumbnail")

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "🖼️"; font.pixelSize: 26; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Thumbnail"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeBody; font.weight: Font.DemiBold; color: Theme.textPrimary; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Download cover art"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTiny; color: Theme.textMuted; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }
            }
        }
    }

    function handleInput(text, mode) {
        if (!text) return;
        var trimmed = text.trim();
        // Check if playlist
        if (trimmed.indexOf("list=") !== -1) {
            root.playlistRequested(trimmed);
            return;
        }

        // Check if YouTube URL or video ID
        if (trimmed.indexOf("youtube.com") !== -1 || trimmed.indexOf("youtu.be") !== -1 || trimmed.length === 11) {
            root.isAnalyzing = true;
            if (bridge) bridge.analyzeUrl(trimmed);
        } else {
            // Search query
            root.searchRequested(trimmed);
        }
    }

    Connections {
        target: bridge
        function onAnalysisStarted() {
            root.isAnalyzing = true;
        }
        function onAnalysisFinished(data) {
            root.isAnalyzing = false;
            root.analyzedVideo = data;
        }
        function onAnalysisFailed(friendly, tech) {
            root.isAnalyzing = false;
        }
    }
}

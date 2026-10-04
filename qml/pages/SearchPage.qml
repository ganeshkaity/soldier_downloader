import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    property var searchResults: []
    property bool isSearching: false
    property var selectedVideo: null

    signal videoSelected(var video)

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: 18

        // Header
        Column {
            spacing: 4
            Text {
                text: "Search YouTube"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.Bold
                color: Theme.textPrimary
            }
            Text {
                text: "Find videos and select streams to download without third-party API keys."
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBody
                color: Theme.textSecondary
            }
        }

        // Search Bar Card
        GlassCard {
            width: parent.width
            implicitHeight: 68
            cardColor: Theme.glassCardTranslucent

            Row {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                SearchBar {
                    id: searchInput
                    width: parent.width - searchBtn.width - 12
                    placeholder: "Enter search terms (e.g., Interstellar soundtrack, Python tutorial)..."
                    onAccepted: function(query) {
                        doSearch(query);
                    }
                }

                GlassButton {
                    id: searchBtn
                    text: "Search"
                    variant: "primary"
                    iconText: "🔍"
                    buttonHeight: 44
                    disabled: searchInput.text.trim() === "" || root.isSearching
                    onClicked: doSearch(searchInput.text.trim())
                }
            }
        }

        // Selected Video Configuration Box (when a user picks a search result)
        GlassCard {
            width: parent.width
            implicitHeight: configCol.implicitHeight + 32
            visible: root.selectedVideo !== null
            cardColor: "#142236"
            borderColor: Theme.accent

            Column {
                id: configCol
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                Row {
                    width: parent.width
                    spacing: 16

                    Rectangle {
                        width: 140
                        height: 78
                        radius: Theme.radiusSmall
                        color: "#080c14"
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: root.selectedVideo ? root.selectedVideo.thumbnail_url : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Column {
                        width: parent.width - 140 - 16
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: root.selectedVideo ? root.selectedVideo.title : ""
                            width: parent.width
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSubheading
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            text: (root.selectedVideo ? root.selectedVideo.channel : "") + " • " + (root.selectedVideo ? root.selectedVideo.duration_str : "")
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.borderSubtle }

                FormatSelector {
                    id: searchFormatSelector
                    width: parent.width
                    showAdvancedButton: false
                }

                Row {
                    anchors.right: parent.right
                    spacing: 12
                    topPadding: 4

                    GlassButton {
                        text: "Cancel"
                        variant: "tertiary"
                        buttonHeight: 36
                        onClicked: root.selectedVideo = null
                    }

                    GlassButton {
                        text: "Add to Queue"
                        variant: "primary"
                        iconText: "⬇"
                        buttonHeight: 36
                        onClicked: {
                            if (bridge && root.selectedVideo) {
                                bridge.queueSingleDownload(
                                    root.selectedVideo.url,
                                    root.selectedVideo.video_id,
                                    root.selectedVideo.title,
                                    root.selectedVideo.thumbnail_url,
                                    searchFormatSelector.mediaMode,
                                    searchFormatSelector.videoQuality,
                                    searchFormatSelector.mediaMode === "video" ? searchFormatSelector.videoContainer : searchFormatSelector.audioFormat,
                                    "",
                                    ""
                                );
                                root.selectedVideo = null;
                            }
                        }
                    }
                }
            }
        }

        // Searching Spinner / Progress
        GlassCard {
            width: parent.width
            implicitHeight: 70
            visible: root.isSearching
            cardColor: Theme.glassCardTranslucent

            Row {
                anchors.centerIn: parent
                spacing: 16
                GlassProgressBar { width: 140; value: 50; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "Searching YouTube..."
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBody
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Empty state when no search performed yet or 0 results
        EmptyState {
            width: parent.width
            height: parent.height - 180
            visible: !root.isSearching && root.searchResults.length === 0
            iconText: "🔍"
            title: searchInput.text.trim() === "" ? "Search for media" : "No results found"
            description: searchInput.text.trim() === "" ? 
                "Enter video titles, artist names, or search queries to discover content." : 
                "Try refining your search terms or verify your internet connection."
        }

        // Results View
        ListView {
            id: resultsList
            width: parent.width
            height: parent.height - (root.selectedVideo !== null ? 360 : 160)
            clip: true
            spacing: 12
            visible: !root.isSearching && root.searchResults.length > 0

            model: root.searchResults

            delegate: VideoCard {
                width: resultsList.width
                videoId: modelData.video_id
                title: modelData.title
                channel: modelData.channel
                durationStr: modelData.duration_str
                thumbnailUrl: modelData.thumbnail_url
                viewCountStr: modelData.view_count_str
                uploadDate: modelData.upload_date
                url: modelData.url
                actionText: "Select"

                onSelected: {
                    root.selectedVideo = modelData;
                }

                onCopyUrlRequested: {
                    if (bridge) bridge.copyToClipboard(modelData.url);
                }
            }
        }
    }

    function doSearch(query) {
        if (!query || query.trim() === "") return;
        root.isSearching = true;
        root.selectedVideo = null;
        if (bridge) bridge.search(query.trim(), 20);
    }

    function setSearchQuery(q) {
        searchInput.text = q;
        doSearch(q);
    }

    Connections {
        target: bridge
        function onSearchStarted() {
            root.isSearching = true;
        }
        function onSearchFinished(results) {
            root.isSearching = false;
            root.searchResults = results;
        }
        function onSearchFailed(friendly, tech) {
            root.isSearching = false;
            root.searchResults = [];
        }
    }
}

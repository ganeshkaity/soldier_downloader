import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    property var previewData: null
    property bool isFetching: false

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: 18

        // Header
        Column {
            spacing: 4
            Text {
                text: "Thumbnail Downloader"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.Bold
                color: Theme.textPrimary
            }
            Text {
                text: "Download original high-resolution YouTube cover artwork and thumbnails directly."
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBody
                color: Theme.textSecondary
            }
        }

        // Input Bar Card
        GlassCard {
            width: parent.width
            implicitHeight: 68
            cardColor: Theme.glassCardTranslucent

            Row {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                SearchBar {
                    id: thumbInput
                    width: parent.width - fetchBtn.width - 12
                    placeholder: "Paste YouTube URL or enter search query..."
                    onAccepted: function(query) {
                        fetchThumbnail(query);
                    }
                }

                GlassButton {
                    id: fetchBtn
                    text: "Fetch Preview"
                    variant: "primary"
                    iconText: "🖼️"
                    buttonHeight: 44
                    disabled: thumbInput.text.trim() === "" || root.isFetching
                    onClicked: fetchThumbnail(thumbInput.text.trim())
                }
            }
        }

        // Loading Indicator
        GlassCard {
            width: parent.width
            implicitHeight: 70
            visible: root.isFetching
            cardColor: Theme.glassCardTranslucent

            Row {
                anchors.centerIn: parent
                spacing: 16
                GlassProgressBar { width: 140; value: 50; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "Fetching thumbnail preview..."
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBody
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Empty state
        EmptyState {
            width: parent.width
            height: parent.height - 180
            visible: !root.isFetching && root.previewData === null
            iconText: "🖼️"
            title: "No thumbnail loaded"
            description: "Paste a YouTube URL or enter a search query above to preview and download its cover art."
        }

        // Preview and Download Card
        GlassCard {
            width: parent.width
            height: parent.height - 170
            visible: !root.isFetching && root.previewData !== null
            cardColor: Theme.glassCardTranslucent
            borderColor: Theme.accent

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                Text {
                    text: root.previewData ? root.previewData.title : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeHeading
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    width: parent.width
                }

                // Large Image Preview Frame
                Rectangle {
                    width: parent.width
                    height: parent.height - 110
                    radius: Theme.radiusLarge
                    color: "#080c14"
                    border.color: Theme.borderSubtle
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.previewData ? root.previewData.thumbnail_url : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                }

                // Download Action Row
                Item {
                    width: parent.width
                    height: 40

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Resolution: " + (root.previewData ? root.previewData.resolution : "HD") + " • Saves to Downloads\\Soldiers"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    GlassButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Download Thumbnail"
                        variant: "primary"
                        iconText: "⬇"
                        buttonHeight: 40
                        onClicked: {
                            if (bridge && root.previewData) {
                                bridge.downloadThumbnail(root.previewData.thumbnail_url, root.previewData.title);
                            }
                        }
                    }
                }
            }
        }
    }

    function fetchThumbnail(query) {
        if (!query || query.trim() === "") return;
        root.isFetching = true;
        root.previewData = null;
        if (bridge) bridge.fetchThumbnailPreview(query.trim());
    }

    function setQuery(q) {
        thumbInput.text = q;
        fetchThumbnail(q);
    }

    Connections {
        target: bridge
        function onThumbnailPreviewReady(data) {
            root.isFetching = false;
            root.previewData = data;
        }
        function onThumbnailPreviewFailed(err) {
            root.isFetching = false;
            root.previewData = null;
        }
    }
}

import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    property var queueList: bridge ? bridge.queueItems : []

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: 16

        // Header Row
        Item {
            width: parent.width
            height: 52

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Text {
                    text: "Download Queue"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeTitle
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                }
                Text {
                    text: (bridge ? bridge.activeCount : 0) + " active • " + 
                          (bridge ? bridge.queuedCount : 0) + " queued • " + 
                          (bridge ? bridge.completedCount : 0) + " completed"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBody
                    color: Theme.textSecondary
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                GlassButton {
                    text: bridge && bridge.isQueuePaused ? "Resume Downloads" : "Pause Downloads"
                    variant: "secondary"
                    iconText: bridge && bridge.isQueuePaused ? "▶" : "⏸"
                    buttonHeight: 36
                    onClicked: {
                        if (bridge) bridge.toggleQueuePause();
                    }
                }

                GlassButton {
                    text: "Clear Completed"
                    variant: "tertiary"
                    buttonHeight: 36
                    disabled: bridge ? bridge.completedCount === 0 : true
                    onClicked: {
                        if (bridge) bridge.clearCompletedQueue();
                    }
                }

                GlassButton {
                    text: "Clear All"
                    variant: "destructive"
                    buttonHeight: 36
                    disabled: root.queueList.length === 0
                    onClicked: {
                        if (confirmDialog) {
                            confirmDialog.openDialog(
                                "Clear Download Queue",
                                "Are you sure you want to cancel all active downloads and clear the entire queue?",
                                function() {
                                    if (bridge) bridge.clearAllQueue();
                                },
                                "destructive"
                            );
                        }
                    }
                }
            }
        }

        // Empty state when queue is empty
        EmptyState {
            width: parent.width
            height: parent.height - 120
            visible: root.queueList.length === 0
            iconText: "📥"
            title: "Nothing downloading"
            description: "Your download queue is currently empty.\nPaste a YouTube URL or search for something to begin."
        }

        // Queue Items ListView
        ListView {
            id: queueListView
            width: parent.width
            height: parent.height - 80
            clip: true
            spacing: 10
            visible: root.queueList.length > 0

            model: root.queueList

            delegate: DownloadQueueItem {
                width: queueListView.width
                itemId: modelData.id
                title: modelData.title
                thumbnailUrl: modelData.thumbnail_url
                mediaType: modelData.media_type
                quality: modelData.quality
                outputFormat: modelData.format
                status: modelData.status
                progressPercent: modelData.progress_percent
                speedStr: modelData.speed_str
                etaStr: modelData.eta_str
                downloadedStr: modelData.downloaded_str
                totalStr: modelData.total_str
                destinationFile: modelData.destination_file
                errorMessage: modelData.error_message

                onCancelClicked: function(id) {
                    if (bridge) bridge.cancelDownload(id);
                }
                onRetryClicked: function(id) {
                    if (bridge) bridge.retryDownload(id);
                }
                onOpenFileClicked: function(path) {
                    if (bridge) bridge.openFile(path);
                }
                onOpenFolderClicked: function(path) {
                    if (bridge) bridge.openFolder(path);
                }
                onRemoveClicked: function(id) {
                    if (bridge) bridge.removeQueueItem(id);
                }
            }
        }
    }

    Connections {
        target: bridge
        function onQueueChanged() {
            root.queueList = bridge.queueItems;
        }
        function onItemProgressUpdated(id, percent, speed, eta, down, total, status) {
            // Live update is reflected because bridge.queueItems updates
            root.queueList = bridge.queueItems;
        }
    }
}

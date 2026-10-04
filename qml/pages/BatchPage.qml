import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import "../components"

Item {
    id: root

    property var parsedItems: []
    property var resolvedItems: []
    property bool isResolving: false
    property var importSummary: null

    FileDialog {
        id: fileDialog
        title: "Import URLs from Text File"
        nameFilters: ["Text files (*.txt)", "All files (*.*)"]
        onAccepted: {
            if (fileDialog.selectedFile && bridge) {
                var res = bridge.importTxtFile(fileDialog.selectedFile.toString());
                if (res && res.success) {
                    root.importSummary = res;
                    root.parsedItems = res.items;
                    resolveItems();
                } else if (res && bridge) {
                    bridge.showToast("error", res.error || "Failed importing file.");
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: 16

        // Header
        Column {
            spacing: 4
            Text {
                text: "Batch & TXT Downloader"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.Bold
                color: Theme.textPrimary
            }
            Text {
                text: "Paste multiple URLs/search queries or import a .txt file."
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBody
                color: Theme.textSecondary
            }
        }

        // Multi-line Input Card (Visible when review list is empty)
        GlassCard {
            width: parent.width
            implicitHeight: 220
            visible: root.resolvedItems.length === 0
            cardColor: Theme.glassCardTranslucent

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                ScrollView {
                    width: parent.width
                    height: parent.height - 48
                    clip: true

                    TextArea {
                        id: batchInputArea
                        width: parent.width
                        placeholderText: "Paste YouTube URLs or search queries (one per line)...\nExample:\nhttps://youtube.com/watch?v=...\nPython tutorial for beginners\nhttps://youtu.be/..."
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeBody
                        background: null
                        selectByMouse: true
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: 12

                    GlassButton {
                        text: "Import .TXT"
                        variant: "secondary"
                        iconText: "📂"
                        buttonHeight: 36
                        onClicked: fileDialog.open()
                    }

                    GlassButton {
                        text: "Clear"
                        variant: "tertiary"
                        buttonHeight: 36
                        onClicked: {
                            batchInputArea.text = "";
                            root.importSummary = null;
                        }
                    }

                    GlassButton {
                        text: "Parse & Review"
                        variant: "primary"
                        iconText: "✓"
                        buttonHeight: 36
                        disabled: batchInputArea.text.trim() === "" || root.isResolving
                        onClicked: {
                            if (bridge) {
                                var items = bridge.parseBatchLines(batchInputArea.text);
                                root.parsedItems = items;
                                resolveItems();
                            }
                        }
                    }
                }
            }
        }

        // Import Summary Banner (if imported from TXT)
        GlassCard {
            width: parent.width
            implicitHeight: 48
            visible: root.importSummary !== null
            cardColor: "#102336"
            borderColor: Theme.accent

            Row {
                anchors.centerIn: parent
                spacing: 24

                Text {
                    text: "Total: " + (root.importSummary ? root.importSummary.total : 0)
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "Valid: " + (root.importSummary ? root.importSummary.valid : 0)
                    color: Theme.statusSuccess
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "Duplicates: " + (root.importSummary ? root.importSummary.duplicates : 0)
                    color: Theme.statusWarning
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }
                Text {
                    text: "Invalid: " + (root.importSummary ? root.importSummary.invalid : 0)
                    color: Theme.statusError
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }

        // Resolving search queries spinner
        GlassCard {
            width: parent.width
            implicitHeight: 64
            visible: root.isResolving
            cardColor: Theme.glassCardTranslucent

            Row {
                anchors.centerIn: parent
                spacing: 16
                GlassProgressBar { width: 140; value: 50; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "Resolving YouTube search queries into video targets..."
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBody
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Review List & Format Controls (Visible when items are resolved)
        Column {
            width: parent.width
            height: parent.height - 180
            spacing: 12
            visible: root.resolvedItems.length > 0 && !root.isResolving

            Item {
                width: parent.width
                height: 36

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.resolvedItems.length + " Items Ready to Queue"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSubheading
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    GlassButton {
                        text: "Back to Edit"
                        variant: "tertiary"
                        buttonHeight: 32
                        onClicked: {
                            root.resolvedItems = [];
                        }
                    }

                    GlassButton {
                        text: "Clear All"
                        variant: "tertiary"
                        buttonHeight: 32
                        onClicked: {
                            root.resolvedItems = [];
                            root.parsedItems = [];
                            root.importSummary = null;
                            batchInputArea.text = "";
                        }
                    }
                }
            }

            // Items ListView
            ListView {
                id: batchListView
                width: parent.width
                height: parent.height - batchBottomBar.height - 48
                clip: true
                spacing: 8

                model: root.resolvedItems

                delegate: GlassCard {
                    width: batchListView.width
                    implicitHeight: 52
                    cardColor: Theme.glassCardTranslucent

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            width: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: "" + (index + 1)
                            color: Theme.textMuted
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        // Thumbnail or icon
                        Rectangle {
                            width: 44
                            height: 28
                            radius: 4
                            color: "#080c14"
                            clip: true
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                anchors.fill: parent
                                source: modelData.thumbnail_url || ""
                                fillMode: Image.PreserveAspectCrop
                                visible: modelData.thumbnail_url !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.type === "url" ? "🔗" : "🔍"
                                visible: !modelData.thumbnail_url
                                font.pixelSize: 12
                            }
                        }

                        // Title or query
                        Column {
                            width: parent.width - 24 - 44 - 40 - 36
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: modelData.title || modelData.raw_text || modelData.query
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeBody
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelData.url || (modelData.original_query ? "Resolved from: " + modelData.original_query : "")
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeTiny
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Remove button
                        GlassButton {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "✕"
                            variant: "tertiary"
                            buttonHeight: 28
                            customRadius: 4
                            implicitWidth: 28
                            onClicked: {
                                var copy = root.resolvedItems.slice();
                                copy.splice(index, 1);
                                root.resolvedItems = copy;
                            }
                        }
                    }
                }
            }

            // Bottom Configuration Bar
            GlassCard {
                id: batchBottomBar
                width: parent.width
                implicitHeight: bCol.implicitHeight + 24
                cardColor: "#121d2d"
                borderColor: Theme.accent

                Column {
                    id: bCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    FormatSelector {
                        id: batchFormatSelector
                        width: parent.width
                        showAdvancedButton: false
                    }

                    Item {
                        width: parent.width
                        height: 38

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Format will apply to all " + root.resolvedItems.length + " items"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.accent
                        }

                        GlassButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Add All to Queue"
                            variant: "primary"
                            iconText: "⬇"
                            buttonHeight: 38
                            disabled: root.resolvedItems.length === 0
                            onClicked: queueAll()
                        }
                    }
                }
            }
        }
    }

    function resolveItems() {
        if (!bridge || root.parsedItems.length === 0) return;
        root.isResolving = true;
        bridge.resolveBatchSearchTerms(root.parsedItems);
    }

    function queueAll() {
        if (!bridge || root.resolvedItems.length === 0) return;
        var validToQueue = root.resolvedItems.filter(function(itm) {
            return itm.url && itm.url !== "";
        });

        bridge.queueBatchDownloads(
            validToQueue,
            batchFormatSelector.mediaMode,
            batchFormatSelector.videoQuality,
            batchFormatSelector.mediaMode === "video" ? batchFormatSelector.videoContainer : batchFormatSelector.audioFormat
        );

        root.resolvedItems = [];
        root.parsedItems = [];
        root.importSummary = null;
        batchInputArea.text = "";
    }

    Connections {
        target: bridge
        function onBatchResolved(results) {
            root.isResolving = false;
            root.resolvedItems = results;
        }
        function onBatchFailed(err) {
            root.isResolving = false;
        }
    }
}

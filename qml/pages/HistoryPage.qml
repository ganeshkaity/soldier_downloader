import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    property var historyItems: []
    property string currentFilter: "All"
    property string currentSort: "Newest"
    property string searchQuery: ""

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
                    text: "Download History"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeTitle
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                }
                Text {
                    text: "Locally recorded downloads saved to SQLite database."
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
                    text: "Clean Missing Files"
                    variant: "secondary"
                    buttonHeight: 36
                    onClicked: {
                        if (bridge) {
                            bridge.cleanMissingFiles();
                            refreshHistory();
                        }
                    }
                }

                GlassButton {
                    text: "Clear History"
                    variant: "destructive"
                    buttonHeight: 36
                    disabled: root.historyItems.length === 0
                    onClicked: {
                        if (confirmDialog) {
                            confirmDialog.openDialog(
                                "Clear Download History",
                                "Are you sure you want to clear your local download history records? Physical media files on disk will NOT be deleted.",
                                function() {
                                    if (bridge) {
                                        bridge.clearAllHistory();
                                        refreshHistory();
                                    }
                                },
                                "destructive"
                            );
                        }
                    }
                }
            }
        }

        // Filter and Search Bar Card
        GlassCard {
            width: parent.width
            implicitHeight: 56
            cardColor: Theme.glassCardTranslucent

            Item {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    // Search Box
                    Rectangle {
                        width: 240
                        height: 36
                        radius: Theme.radiusSmall
                        color: Theme.glassInput
                        border.color: histSearchInput.activeFocus ? Theme.accent : Theme.borderSubtle
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Text { text: "🔍"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; opacity: 0.5 }

                            TextInput {
                                id: histSearchInput
                                width: parent.width - 24
                                anchors.verticalCenter: parent.verticalCenter
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                selectByMouse: true

                                Text {
                                    text: "Search downloads..."
                                    color: Theme.textMuted
                                    font.pixelSize: Theme.fontSizeSmall
                                    visible: !histSearchInput.text && !histSearchInput.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                onTextChanged: {
                                    root.searchQuery = text;
                                    refreshHistory();
                                }
                            }
                        }
                    }

                    // Filter Pills
                    Row {
                        spacing: 6

                        Repeater {
                            model: ["All", "Completed", "Failed", "Audio", "Video"]

                            Rectangle {
                                width: fLabel.implicitWidth + 16
                                height: 30
                                radius: Theme.radiusSmall
                                color: root.currentFilter === modelData ? Theme.glassActive : "transparent"
                                border.color: root.currentFilter === modelData ? Theme.accent : Theme.borderSubtle
                                border.width: 1

                                Text {
                                    id: fLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: root.currentFilter === modelData ? Theme.accent : Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: root.currentFilter === modelData ? Font.DemiBold : Font.Normal
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.currentFilter = modelData;
                                        refreshHistory();
                                    }
                                }
                            }
                        }
                    }
                }

                // Sort By Dropdown
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Sort:"
                        color: Theme.textMuted
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Repeater {
                        model: ["Newest", "Oldest", "Name", "Size"]

                        Rectangle {
                            width: sLabel.implicitWidth + 12
                            height: 28
                            radius: 4
                            color: root.currentSort === modelData ? Theme.glassActive : "transparent"
                            border.color: root.currentSort === modelData ? Theme.borderCard : "transparent"
                            border.width: 1

                            Text {
                                id: sLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: root.currentSort === modelData ? Theme.textPrimary : Theme.textMuted
                                font.pixelSize: Theme.fontSizeTiny
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.currentSort = modelData;
                                    refreshHistory();
                                }
                            }
                        }
                    }
                }
            }
        }

        // Empty State
        EmptyState {
            width: parent.width
            height: parent.height - 180
            visible: root.historyItems.length === 0
            iconText: "📜"
            title: "No downloads yet"
            description: "Completed and attempted downloads will be permanently logged here."
        }

        // History Items ListView
        ListView {
            id: historyListView
            width: parent.width
            height: parent.height - 150
            clip: true
            spacing: 8
            visible: root.historyItems.length > 0

            model: root.historyItems

            delegate: GlassCard {
                width: historyListView.width
                implicitHeight: 68
                cardColor: Theme.glassCardTranslucent

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 14

                    // Thumbnail / Icon
                    Rectangle {
                        width: 72
                        height: 44
                        radius: Theme.radiusSmall
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
                            text: modelData.media_type === "audio" ? "🎵" : "🎬"
                            visible: !modelData.thumbnail_url
                            font.pixelSize: 18
                        }
                    }

                    // Title & Metadata
                    Column {
                        width: parent.width - 72 - 14 - histActions.width - 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: modelData.title
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeBody
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Row {
                            spacing: 10
                            Text {
                                text: modelData.output_format.toUpperCase() + " • " + modelData.quality
                                color: Theme.accent
                                font.pixelSize: Theme.fontSizeTiny
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "• " + modelData.file_size_str
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeTiny
                                visible: modelData.file_size > 0
                            }
                            Text {
                                text: "• " + modelData.date_time
                                color: Theme.textMuted
                                font.pixelSize: Theme.fontSizeTiny
                            }
                            Text {
                                text: modelData.file_exists ? "✓ On Disk" : "✕ File Missing"
                                color: modelData.file_exists ? Theme.statusSuccess : Theme.statusWarning
                                font.pixelSize: Theme.fontSizeTiny
                                visible: modelData.status === "Completed"
                            }
                        }
                    }

                    // Action Buttons
                    Row {
                        id: histActions
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Open File
                        GlassButton {
                            visible: modelData.status === "Completed" && modelData.file_exists
                            text: "Open"
                            variant: "secondary"
                            buttonHeight: 32
                            customRadius: Theme.radiusSmall
                            onClicked: {
                                if (bridge) bridge.openFile(modelData.file_path);
                            }
                        }

                        // Open Folder
                        GlassButton {
                            visible: modelData.status === "Completed" && modelData.file_exists
                            text: "📁"
                            variant: "tertiary"
                            buttonHeight: 32
                            customRadius: Theme.radiusSmall
                            implicitWidth: 32
                            onClicked: {
                                if (bridge) bridge.openFolder(modelData.file_path);
                            }
                        }

                        // Redownload
                        GlassButton {
                            text: "⬇ Re-queue"
                            variant: "secondary"
                            buttonHeight: 32
                            customRadius: Theme.radiusSmall
                            onClicked: {
                                if (bridge) {
                                    bridge.queueSingleDownload(
                                        modelData.url,
                                        modelData.video_id,
                                        modelData.title,
                                        modelData.thumbnail_url,
                                        modelData.media_type,
                                        modelData.quality,
                                        modelData.output_format,
                                        "",
                                        ""
                                    );
                                }
                            }
                        }

                        // Delete record
                        GlassButton {
                            text: "✕"
                            variant: "tertiary"
                            buttonHeight: 32
                            customRadius: Theme.radiusSmall
                            implicitWidth: 32
                            onClicked: {
                                if (bridge) {
                                    bridge.deleteHistoryItem(modelData.id);
                                    refreshHistory();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function refreshHistory() {
        if (bridge) {
            root.historyItems = bridge.getHistory(root.searchQuery, root.currentFilter, root.currentSort);
        }
    }

    Component.onCompleted: {
        refreshHistory();
    }
}

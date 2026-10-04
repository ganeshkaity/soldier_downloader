import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    property var playlistData: null
    property bool isExtracting: false
    property var selectedIndices: []
    property int selectedCount: selectedIndices.length

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: 16

        // Title and description
        Column {
            spacing: 4
            Text {
                text: "Playlist Downloader"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.Bold
                color: Theme.textPrimary
            }
            Text {
                text: "Extract and batch download YouTube playlists with selective filtering."
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBody
                color: Theme.textSecondary
            }
        }

        // URL Input Bar
        GlassCard {
            width: parent.width
            implicitHeight: 68
            cardColor: Theme.glassCardTranslucent

            Row {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                SearchBar {
                    id: playlistUrlInput
                    width: parent.width - analyzeBtn.width - 12
                    placeholder: "Paste YouTube Playlist URL (e.g., https://www.youtube.com/playlist?list=...)..."
                    onAccepted: function(query) {
                        analyzePlaylist(query);
                    }
                }

                GlassButton {
                    id: analyzeBtn
                    text: "Analyze"
                    variant: "primary"
                    iconText: "📑"
                    buttonHeight: 44
                    disabled: playlistUrlInput.text.trim() === "" || root.isExtracting
                    onClicked: analyzePlaylist(playlistUrlInput.text.trim())
                }
            }
        }

        // Loading Indicator
        GlassCard {
            width: parent.width
            implicitHeight: 70
            visible: root.isExtracting
            cardColor: Theme.glassCardTranslucent

            Row {
                anchors.centerIn: parent
                spacing: 16
                GlassProgressBar { width: 140; value: 50; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "Extracting playlist entries..."
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBody
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Empty state when no playlist loaded
        EmptyState {
            width: parent.width
            height: parent.height - 180
            visible: !root.isExtracting && root.playlistData === null
            iconText: "📑"
            title: "No playlist loaded"
            description: "Paste a YouTube playlist URL above to inspect and select individual videos."
        }

        // Playlist View when loaded
        Column {
            width: parent.width
            height: parent.height - 160
            spacing: 12
            visible: !root.isExtracting && root.playlistData !== null

            // Playlist Controls and Range Selection Bar
            GlassCard {
                width: parent.width
                implicitHeight: controlsCol.implicitHeight + 24
                cardColor: Theme.glassCardTranslucent

                Column {
                    id: controlsCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // Top Row: Playlist Title, Count, Selection Controls
                    Item {
                        width: parent.width
                        height: 38

                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                text: root.playlistData ? root.playlistData.title : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSubheading
                                font.weight: Font.Bold
                                color: Theme.textPrimary
                            }
                            Text {
                                text: (root.playlistData ? root.playlistData.entry_count : 0) + " total videos • " + root.selectedCount + " selected"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.accent
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            GlassButton {
                                text: "Select All"
                                variant: "secondary"
                                buttonHeight: 32
                                customRadius: Theme.radiusSmall
                                onClicked: selectAll()
                            }
                            GlassButton {
                                text: "Clear"
                                variant: "tertiary"
                                buttonHeight: 32
                                customRadius: Theme.radiusSmall
                                onClicked: deselectAll()
                            }
                            GlassButton {
                                text: "Invert"
                                variant: "tertiary"
                                buttonHeight: 32
                                customRadius: Theme.radiusSmall
                                onClicked: invertSelection()
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.borderSubtle }

                    // Bottom Row: Range and First N Selector
                    Row {
                        width: parent.width
                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Range:"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        // From input
                        Rectangle {
                            width: 50
                            height: 28
                            radius: 4
                            color: Theme.glassInput
                            border.color: Theme.borderSubtle
                            border.width: 1
                            TextInput {
                                id: rangeFromInput
                                anchors.fill: parent
                                anchors.margins: 4
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeSmall
                                text: "1"
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "to"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        // To input
                        Rectangle {
                            width: 50
                            height: 28
                            radius: 4
                            color: Theme.glassInput
                            border.color: Theme.borderSubtle
                            border.width: 1
                            TextInput {
                                id: rangeToInput
                                anchors.fill: parent
                                anchors.margins: 4
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeSmall
                                text: root.playlistData ? "" + root.playlistData.entry_count : "10"
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                            }
                        }

                        GlassButton {
                            text: "Select Range"
                            variant: "secondary"
                            buttonHeight: 28
                            customRadius: 4
                            onClicked: applyRange()
                        }

                        Rectangle { width: 1; height: 20; color: Theme.borderSubtle; anchors.verticalCenter: parent.verticalCenter }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "First N:"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Rectangle {
                            width: 50
                            height: 28
                            radius: 4
                            color: Theme.glassInput
                            border.color: Theme.borderSubtle
                            border.width: 1
                            TextInput {
                                id: firstNInput
                                anchors.fill: parent
                                anchors.margins: 4
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeSmall
                                text: "10"
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                            }
                        }

                        GlassButton {
                            text: "Select"
                            variant: "secondary"
                            buttonHeight: 28
                            customRadius: 4
                            onClicked: applyFirstN()
                        }
                    }
                }
            }

            // Playlist Entries List
            ListView {
                id: entriesView
                width: parent.width
                height: parent.height - controlsCol.height - bottomBar.height - 40
                clip: true
                spacing: 6

                model: root.playlistData ? root.playlistData.entries : []

                delegate: PlaylistItem {
                    width: entriesView.width
                    itemIndex: index + 1
                    title: modelData.title
                    channel: modelData.channel
                    durationStr: modelData.duration_str
                    thumbnailUrl: modelData.thumbnail_url
                    isSelected: root.selectedIndices.indexOf(index) !== -1

                    onToggled: function(sel) {
                        var arr = root.selectedIndices.slice();
                        var idx = arr.indexOf(index);
                        if (sel && idx === -1) {
                            arr.push(index);
                        } else if (!sel && idx !== -1) {
                            arr.splice(idx, 1);
                        }
                        root.selectedIndices = arr;
                    }
                }
            }

            // Sticky Bottom Download Configuration Bar
            GlassCard {
                id: bottomBar
                width: parent.width
                implicitHeight: bottomBarCol.implicitHeight + 24
                cardColor: "#121d2d"
                borderColor: Theme.accent

                Column {
                    id: bottomBarCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Format configuration applying globally to selected entries
                    FormatSelector {
                        id: playlistFormatSelector
                        width: parent.width
                        showAdvancedButton: false
                    }

                    Item {
                        width: parent.width
                        height: 38

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.selectedCount + " videos ready for download"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeBody
                            font.weight: Font.DemiBold
                            color: Theme.accent
                        }

                        GlassButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Add Selected to Queue"
                            variant: "primary"
                            iconText: "⬇"
                            buttonHeight: 38
                            disabled: root.selectedCount === 0
                            onClicked: queueSelected()
                        }
                    }
                }
            }
        }
    }

    function analyzePlaylist(url) {
        if (!url || url.trim() === "") return;
        root.isExtracting = true;
        root.playlistData = null;
        root.selectedIndices = [];
        if (bridge) bridge.analyzePlaylist(url.trim());
    }

    function setPlaylistUrl(u) {
        playlistUrlInput.text = u;
        analyzePlaylist(u);
    }

    function selectAll() {
        if (!root.playlistData) return;
        var all = [];
        for (var i = 0; i < root.playlistData.entry_count; i++) {
            all.push(i);
        }
        root.selectedIndices = all;
    }

    function deselectAll() {
        root.selectedIndices = [];
    }

    function invertSelection() {
        if (!root.playlistData) return;
        var inv = [];
        for (var i = 0; i < root.playlistData.entry_count; i++) {
            if (root.selectedIndices.indexOf(i) === -1) {
                inv.push(i);
            }
        }
        root.selectedIndices = inv;
    }

    function applyRange() {
        if (!root.playlistData || !bridge) return;
        var start = parseInt(rangeFromInput.text) || 1;
        var end = parseInt(rangeToInput.text) || root.playlistData.entry_count;
        var res = bridge.calculatePlaylistRange(root.playlistData.entry_count, start, end);
        root.selectedIndices = res;
    }

    function applyFirstN() {
        if (!root.playlistData || !bridge) return;
        var n = parseInt(firstNInput.text) || 0;
        var res = bridge.calculatePlaylistFirstN(root.playlistData.entry_count, n);
        root.selectedIndices = res;
    }

    function queueSelected() {
        if (!root.playlistData || !bridge || root.selectedIndices.length === 0) return;
        var itemsToQueue = [];
        for (var i = 0; i < root.selectedIndices.length; i++) {
            var idx = root.selectedIndices[i];
            if (idx >= 0 && idx < root.playlistData.entries.length) {
                itemsToQueue.push(root.playlistData.entries[idx]);
            }
        }

        bridge.queueBatchDownloads(
            itemsToQueue,
            playlistFormatSelector.mediaMode,
            playlistFormatSelector.videoQuality,
            playlistFormatSelector.mediaMode === "video" ? playlistFormatSelector.videoContainer : playlistFormatSelector.audioFormat
        );
    }

    Connections {
        target: bridge
        function onPlaylistStarted() {
            root.isExtracting = true;
        }
        function onPlaylistFinished(data) {
            root.isExtracting = false;
            root.playlistData = data;
            // Default: select all
            selectAll();
        }
        function onPlaylistFailed(friendly, tech) {
            root.isExtracting = false;
            root.playlistData = null;
        }
    }
}

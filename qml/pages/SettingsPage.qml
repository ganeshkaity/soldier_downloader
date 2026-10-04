import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import "../components"

Item {
    id: root

    property var currentSettings: bridge ? bridge.getSettings() : {}

    property string downloadDir: currentSettings.download_dir || ""
    property int concurrentDownloads: currentSettings.concurrent_downloads || 5
    property string defaultVideoQuality: currentSettings.default_video_quality || "Best"
    property string defaultAudioFormat: currentSettings.default_audio_format || "MP3"
    property string duplicateMode: currentSettings.duplicate_mode || "Skip"
    property bool filenameSanitization: currentSettings.filename_sanitization !== undefined ? currentSettings.filename_sanitization : true
    property bool minimizeToTray: currentSettings.minimize_to_tray !== undefined ? currentSettings.minimize_to_tray : true
    property string closeBehavior: currentSettings.close_behavior || "Minimize to tray"

    property var ytdlpUpdateInfo: null

    FolderDialog {
        id: folderDialog
        title: "Select Download Destination Folder"
        onAccepted: {
            if (folderDialog.selectedFolder) {
                var folderPath = folderDialog.selectedFolder.toString();
                if (folderPath.startsWith("file:///")) {
                    folderPath = folderPath.substring(8);
                    if (folderPath.length >= 3 && folderPath.charAt(0) === '/' && folderPath.charAt(2) === ':') {
                        folderPath = folderPath.substring(1);
                    }
                }
                root.downloadDir = folderPath;
                saveCurrentSettings();
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        clip: true
        contentWidth: availableWidth

        Column {
            width: parent.width
            spacing: 20

            // Header Row
            Item {
                width: parent.width
                height: 52

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text {
                        text: "Application Settings"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTitle
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                    }
                    Text {
                        text: "Configure local paths, concurrency limits, quality defaults, and tray behavior."
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeBody
                        color: Theme.textSecondary
                    }
                }

                GlassButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Reset Defaults"
                    variant: "tertiary"
                    buttonHeight: 36
                    onClicked: {
                        if (bridge) {
                            bridge.resetSettings();
                            root.currentSettings = bridge.getSettings();
                            refreshValues();
                        }
                    }
                }
            }

            // Group 1: Storage & Directories
            GlassCard {
                width: parent.width
                implicitHeight: storageCol.implicitHeight + 32
                cardColor: Theme.glassCardTranslucent

                Column {
                    id: storageCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Text {
                        text: "Storage & File Locations"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeHeading
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }

                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: "Download Directory"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Row {
                            width: parent.width
                            spacing: 10

                            Rectangle {
                                width: parent.width - 200
                                height: 38
                                radius: Theme.radiusSmall
                                color: Theme.glassInput
                                border.color: Theme.borderSubtle
                                border.width: 1

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    verticalAlignment: Text.AlignVCenter
                                    text: root.downloadDir
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    elide: Text.ElideMiddle
                                }
                            }

                            GlassButton {
                                text: "Browse..."
                                variant: "secondary"
                                buttonHeight: 38
                                onClicked: folderDialog.open()
                            }

                            GlassButton {
                                text: "Open"
                                variant: "tertiary"
                                buttonHeight: 38
                                onClicked: {
                                    if (bridge) bridge.openDownloadsFolder();
                                }
                            }
                        }
                    }

                    // Duplicate Behavior
                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: "When File Already Exists"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Row {
                            spacing: 8
                            Repeater {
                                model: ["Skip", "Overwrite"]

                                Rectangle {
                                    width: dupLabel.implicitWidth + 24
                                    height: 32
                                    radius: Theme.radiusSmall
                                    color: root.duplicateMode === modelData ? Theme.glassActive : Theme.glassCard
                                    border.color: root.duplicateMode === modelData ? Theme.accent : Theme.borderSubtle
                                    border.width: 1

                                    Text {
                                        id: dupLabel
                                        anchors.centerIn: parent
                                        text: modelData === "Skip" ? "Skip Existing (Default)" : "Overwrite"
                                        color: root.duplicateMode === modelData ? Theme.accent : Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: root.duplicateMode === modelData ? Font.DemiBold : Font.Normal
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.duplicateMode = modelData;
                                            saveCurrentSettings();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Group 2: Download Concurrency & Defaults
            GlassCard {
                width: parent.width
                implicitHeight: defaultsCol.implicitHeight + 32
                cardColor: Theme.glassCardTranslucent

                Column {
                    id: defaultsCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    Text {
                        text: "Concurrency & Media Defaults"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeHeading
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }

                    // Concurrent Downloads Slider/Pills
                    Column {
                        width: parent.width
                        spacing: 8

                        Row {
                            spacing: 12
                            Text {
                                text: "Maximum Simultaneous Downloads:"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                            }
                            Text {
                                text: "" + root.concurrentDownloads
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                            }
                        }

                        Row {
                            spacing: 6
                            Repeater {
                                model: [1, 2, 3, 4, 5, 6, 8, 10]

                                Rectangle {
                                    width: 38
                                    height: 32
                                    radius: Theme.radiusSmall
                                    color: root.concurrentDownloads === modelData ? Theme.glassActive : Theme.glassCard
                                    border.color: root.concurrentDownloads === modelData ? Theme.accent : Theme.borderSubtle
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "" + modelData
                                        color: root.concurrentDownloads === modelData ? Theme.accent : Theme.textPrimary
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: root.concurrentDownloads === modelData ? Font.Bold : Font.Normal
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.concurrentDownloads = modelData;
                                            saveCurrentSettings();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Default Video Quality
                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: "Default Video Quality"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Flow {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: ["Best", "2160p", "1440p", "1080p", "720p", "480p", "360p"]

                                Rectangle {
                                    width: vLabel.implicitWidth + 20
                                    height: 30
                                    radius: Theme.radiusSmall
                                    color: root.defaultVideoQuality === modelData ? Theme.glassActive : Theme.glassCard
                                    border.color: root.defaultVideoQuality === modelData ? Theme.accent : Theme.borderSubtle
                                    border.width: 1

                                    Text {
                                        id: vLabel
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: root.defaultVideoQuality === modelData ? Theme.accent : Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.defaultVideoQuality = modelData;
                                            saveCurrentSettings();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Default Audio Format
                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: "Default Audio Format"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Flow {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: ["Best Audio", "MP3", "M4A", "FLAC", "OPUS", "WAV", "AAC"]

                                Rectangle {
                                    width: aLabel.implicitWidth + 20
                                    height: 30
                                    radius: Theme.radiusSmall
                                    color: root.defaultAudioFormat === modelData ? Theme.glassActive : Theme.glassCard
                                    border.color: root.defaultAudioFormat === modelData ? Theme.accent : Theme.borderSubtle
                                    border.width: 1

                                    Text {
                                        id: aLabel
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: root.defaultAudioFormat === modelData ? Theme.accent : Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.defaultAudioFormat = modelData;
                                            saveCurrentSettings();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Group 3: Windows System Tray & Window Behavior
            GlassCard {
                width: parent.width
                implicitHeight: trayCol.implicitHeight + 32
                cardColor: Theme.glassCardTranslucent

                Column {
                    id: trayCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Text {
                        text: "Windows System Tray & Close Action"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeHeading
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }

                    Row {
                        spacing: 12
                        Rectangle {
                            width: 22
                            height: 22
                            radius: 4
                            color: root.minimizeToTray ? Theme.accent : "transparent"
                            border.color: root.minimizeToTray ? Theme.accent : Theme.borderSubtle
                            border.width: 1.5
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: Theme.textOnAccent
                                visible: root.minimizeToTray
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.minimizeToTray = !root.minimizeToTray;
                                    saveCurrentSettings();
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Enable Windows System Tray Integration"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeBody
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 6
                        visible: root.minimizeToTray

                        Text {
                            text: "When Closing Main Window"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Row {
                            spacing: 8
                            Repeater {
                                model: ["Minimize to tray", "Exit application", "Ask"]

                                Rectangle {
                                    width: cLabel.implicitWidth + 24
                                    height: 32
                                    radius: Theme.radiusSmall
                                    color: root.closeBehavior === modelData ? Theme.glassActive : Theme.glassCard
                                    border.color: root.closeBehavior === modelData ? Theme.accent : Theme.borderSubtle
                                    border.width: 1

                                    Text {
                                        id: cLabel
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: root.closeBehavior === modelData ? Theme.accent : Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.closeBehavior = modelData;
                                            saveCurrentSettings();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Group 4: Diagnostics & Tools
            GlassCard {
                width: parent.width
                implicitHeight: diagCol.implicitHeight + 32
                cardColor: Theme.glassCardTranslucent

                Column {
                    id: diagCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Text {
                        text: "Diagnostics & Updates"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeHeading
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }

                    Row {
                        spacing: 16

                        GlassButton {
                            text: "Check yt-dlp Updates"
                            variant: "secondary"
                            buttonHeight: 38
                            onClicked: {
                                if (bridge) {
                                    root.ytdlpUpdateInfo = bridge.checkYtDlpUpdates();
                                    bridge.showToast("info", "yt-dlp version is: " + root.ytdlpUpdateInfo.current_version);
                                }
                            }
                        }

                        GlassButton {
                            text: "Open Logs Folder"
                            variant: "tertiary"
                            buttonHeight: 38
                            onClicked: {
                                if (bridge) bridge.openLogsFolder();
                            }
                        }

                        GlassButton {
                            text: "About Application"
                            variant: "tertiary"
                            buttonHeight: 38
                            onClicked: {
                                if (aboutDialog) aboutDialog.openDialog();
                            }
                        }
                    }
                }
            }
        }
    }

    function saveCurrentSettings() {
        if (!bridge) return;
        var data = {
            "download_dir": root.downloadDir,
            "concurrent_downloads": root.concurrentDownloads,
            "default_video_quality": root.defaultVideoQuality,
            "default_audio_format": root.defaultAudioFormat,
            "duplicate_mode": root.duplicateMode,
            "filename_sanitization": root.filenameSanitization,
            "minimize_to_tray": root.minimizeToTray,
            "close_behavior": root.closeBehavior
        };
        bridge.saveAllSettings(data);
    }

    function refreshValues() {
        root.downloadDir = root.currentSettings.download_dir || "";
        root.concurrentDownloads = root.currentSettings.concurrent_downloads || 5;
        root.defaultVideoQuality = root.currentSettings.default_video_quality || "Best";
        root.defaultAudioFormat = root.currentSettings.default_audio_format || "MP3";
        root.duplicateMode = root.currentSettings.duplicate_mode || "Skip";
        root.minimizeToTray = root.currentSettings.minimize_to_tray !== undefined ? root.currentSettings.minimize_to_tray : true;
        root.closeBehavior = root.currentSettings.close_behavior || "Minimize to tray";
    }
}

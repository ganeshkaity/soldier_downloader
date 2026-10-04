import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    property var formatsList: []
    property string selectedVideoId: ""
    property string selectedAudioId: ""
    property string activeFilter: "all" // "all", "video", "audio", "combined"
    property bool isVisible: false

    signal formatChosen(string videoFmtId, string audioFmtId)

    anchors.fill: parent
    visible: opacity > 0
    opacity: isVisible ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    // Backdrop
    Rectangle {
        anchors.fill: parent
        color: Theme.bgOverlay
        MouseArea { anchors.fill: parent; onClicked: root.isVisible = false }
    }

    // Modal Card
    GlassCard {
        width: Math.min(parent.width - 60, 840)
        height: Math.min(parent.height - 60, 620)
        anchors.centerIn: parent
        cardColor: Theme.bgPanel
        borderColor: Theme.borderHighlight

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // Header
            Item {
                width: parent.width
                height: 36

                Text {
                    text: "Available Stream Formats"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeHeading
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
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

            // Filter Tabs Row
            Row {
                spacing: 8
                Repeater {
                    model: [
                        { key: "all", label: "All Streams" },
                        { key: "video", label: "Video Only" },
                        { key: "audio", label: "Audio Only" },
                        { key: "combined", label: "Combined" }
                    ]

                    Rectangle {
                        width: tabLabel.implicitWidth + 20
                        height: 30
                        radius: Theme.radiusSmall
                        color: root.activeFilter === modelData.key ? Theme.glassActive : Theme.glassCard
                        border.color: root.activeFilter === modelData.key ? Theme.accent : Theme.borderSubtle
                        border.width: 1

                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            color: root.activeFilter === modelData.key ? Theme.accent : Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: root.activeFilter === modelData.key ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeFilter = modelData.key
                        }
                    }
                }
            }

            // Table Header
            Rectangle {
                width: parent.width
                height: 32
                color: Theme.glassCard
                radius: Theme.radiusSmall
                border.color: Theme.borderSubtle
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text { width: 45; text: "ID"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeTiny; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: 70; text: "TYPE"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeTiny; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: 50; text: "EXT"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeTiny; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: 85; text: "RESOLUTION"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeTiny; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: 45; text: "FPS"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeTiny; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: 100; text: "VCODEC"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeTiny; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: 100; text: "ACODEC"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeTiny; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: 75; text: "BITRATE"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeTiny; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: 90; text: "SIZE"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeTiny; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: 80; text: "SELECT"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeTiny; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight }
                }
            }

            // Table Content ListView
            ListView {
                id: formatsView
                width: parent.width
                height: parent.height - 210
                clip: true
                spacing: 4

                model: {
                    if (!root.formatsList) return [];
                    return root.formatsList.filter(function(fmt) {
                        if (root.activeFilter === "video") return fmt.has_video && !fmt.has_audio;
                        if (root.activeFilter === "audio") return fmt.has_audio && !fmt.has_video;
                        if (root.activeFilter === "combined") return fmt.has_video && fmt.has_audio;
                        return true;
                    });
                }

                delegate: Rectangle {
                    width: formatsView.width
                    height: 38
                    radius: Theme.radiusSmall
                    color: (root.selectedVideoId === modelData.format_id || root.selectedAudioId === modelData.format_id) ? 
                           "#1e314d" : (rowMouse.containsMouse ? Theme.glassHover : Theme.glassCardTranslucent)
                    border.color: (root.selectedVideoId === modelData.format_id || root.selectedAudioId === modelData.format_id) ? 
                                  Theme.accent : Theme.borderSubtle
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text { width: 45; text: modelData.format_id; color: Theme.accent; font.pixelSize: Theme.fontSizeSmall; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                        Text { width: 70; text: modelData.format_type; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
                        Text { width: 50; text: modelData.ext; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
                        Text { width: 85; text: modelData.resolution; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                        Text { width: 45; text: modelData.fps > 0 ? "" + modelData.fps : "—"; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
                        Text { width: 100; text: modelData.vcodec !== "none" ? modelData.vcodec : "—"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeTiny; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
                        Text { width: 100; text: modelData.acodec !== "none" ? modelData.acodec : "—"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeTiny; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
                        Text { width: 75; text: modelData.tbr > 0 ? modelData.tbr + "k" : (modelData.abr > 0 ? modelData.abr + "k" : "—"); color: Theme.textSecondary; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
                        Text { width: 90; text: modelData.filesize_str; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }

                        Item {
                            width: 80
                            height: 28
                            anchors.verticalCenter: parent.verticalCenter

                            GlassButton {
                                anchors.right: parent.right
                                buttonHeight: 26
                                text: {
                                    if (root.selectedVideoId === modelData.format_id || root.selectedAudioId === modelData.format_id) {
                                        return "Selected";
                                    }
                                    return modelData.has_video ? "Pick Video" : "Pick Audio";
                                }
                                variant: (root.selectedVideoId === modelData.format_id || root.selectedAudioId === modelData.format_id) ? "primary" : "secondary"
                                customRadius: 4
                                implicitWidth: 76
                                onClicked: {
                                    if (modelData.has_video && modelData.has_audio) {
                                        root.selectedVideoId = modelData.format_id;
                                        root.selectedAudioId = "";
                                    } else if (modelData.has_video) {
                                        root.selectedVideoId = modelData.format_id;
                                    } else if (modelData.has_audio) {
                                        root.selectedAudioId = modelData.format_id;
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }

            // Bottom action bar
            Item {
                width: parent.width
                height: 44

                Text {
                    anchors.left: parent.left
                    anchors.right: btnRow.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: {
                        var parts = [];
                        if (root.selectedVideoId) parts.push("Video format: " + root.selectedVideoId);
                        if (root.selectedAudioId) parts.push("Audio format: " + root.selectedAudioId);
                        return parts.length > 0 ? parts.join(" + ") : "No explicit format chosen.";
                    }
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                Row {
                    id: btnRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    GlassButton {
                        text: "Clear Selection"
                        variant: "tertiary"
                        buttonHeight: 36
                        onClicked: {
                            root.selectedVideoId = "";
                            root.selectedAudioId = "";
                        }
                    }

                    GlassButton {
                        text: "Apply Format"
                        variant: "primary"
                        buttonHeight: 36
                        disabled: root.selectedVideoId === "" && root.selectedAudioId === ""
                        onClicked: {
                            root.formatChosen(root.selectedVideoId, root.selectedAudioId);
                            root.isVisible = false;
                        }
                    }
                }
            }
        }
    }

    function openWithFormats(list) {
        root.formatsList = list || [];
        root.isVisible = true;
    }
}

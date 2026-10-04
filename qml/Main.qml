import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "components"
import "pages"
import "dialogs"

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 780
    minimumWidth: 1024
    minimumHeight: 640
    title: bridge ? bridge.appName : "Soldier Downloader"
    color: Theme.bgBase

    // Active page tracking
    property string currentPage: "home"
    property bool sidebarCollapsed: width < 1100

    // Root Container
    Row {
        anchors.fill: parent

        // --- Sidebar Navigation ---
        Rectangle {
            id: sidebar
            width: window.sidebarCollapsed ? 76 : 240
            height: parent.height
            color: Theme.bgSidebar
            border.color: Theme.borderSubtle
            border.width: 1

            Behavior on width {
                NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 18

                // App Brand / Logo
                Row {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        width: 44
                        height: 44
                        radius: Theme.radiusMedium
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "🛡️"
                            font.pixelSize: 22
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !window.sidebarCollapsed
                        spacing: 2

                        Text {
                            text: bridge ? bridge.appName : "Soldier Downloader"
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: Theme.textPrimary
                        }

                        Text {
                            text: "Media Utility"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeTiny
                            color: Theme.accent
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.borderSubtle }

                // Navigation Buttons List
                Column {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: [
                            { key: "home", label: "Home", icon: " " },
                            { key: "search", label: "Search", icon: " " },
                            { key: "playlist", label: "Playlist", icon: " " },
                            { key: "batch", label: "Batch & TXT", icon: " " },
                            { key: "queue", label: "Queue", icon: " ", badge: true },
                            { key: "history", label: "History", icon: " " },
                            { key: "thumbnail", label: "Thumbnail", icon: " " },
                            { key: "settings", label: "Settings", icon: " " }
                        ]

                        Rectangle {
                            width: parent.width
                            height: 42
                            radius: Theme.radiusMedium
                            color: window.currentPage === modelData.key ? Theme.glassActive : (navMouse.containsMouse ? Theme.glassHover : "transparent")
                            border.color: window.currentPage === modelData.key ? Theme.accent : "transparent"
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: window.sidebarCollapsed ? 0 : 12
                                spacing: 12

                                Text {
                                    width: window.sidebarCollapsed ? parent.width : 24
                                    text: modelData.icon
                                    font.pixelSize: 17
                                    horizontalAlignment: window.sidebarCollapsed ? Text.AlignHCenter : Text.AlignLeft
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: modelData.label
                                    color: window.currentPage === modelData.key ? Theme.accent : Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeBody
                                    font.weight: window.currentPage === modelData.key ? Font.DemiBold : Font.Normal
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !window.sidebarCollapsed
                                }

                                // Queue item count badge
                                Rectangle {
                                    visible: modelData.badge && (bridge ? (bridge.activeCount + bridge.queuedCount) > 0 : false) && !window.sidebarCollapsed
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    height: 18
                                    width: badgeText.implicitWidth + 10
                                    radius: 9
                                    color: Theme.accent

                                    Text {
                                        id: badgeText
                                        anchors.centerIn: parent
                                        text: "" + (bridge ? (bridge.activeCount + bridge.queuedCount) : 0)
                                        color: Theme.textOnAccent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }
                            }

                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.currentPage = modelData.key
                            }
                        }
                    }
                }
            }

            // Sidebar Bottom Status Indicators (Section 6 & 100)
            Column {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14
                spacing: 8
                visible: !window.sidebarCollapsed

                Rectangle { width: parent.width; height: 1; color: Theme.borderSubtle }

                // yt-dlp Status
                Row {
                    spacing: 8
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: bridge && bridge.environment.yt_dlp.available ? Theme.statusSuccess : Theme.statusError
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "yt-dlp: " + (bridge && bridge.environment.yt_dlp.available ? "Ready" : "Missing")
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTiny
                    }
                }

                // FFmpeg Status
                Row {
                    spacing: 8
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: bridge && bridge.environment.ffmpeg.available ? Theme.statusSuccess : Theme.statusError
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "FFmpeg: " + (bridge && bridge.environment.ffmpeg.available ? "Ready" : "Missing")
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTiny
                    }
                }

                // Version & About Link
                Item {
                    width: parent.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "v" + (bridge ? bridge.appVersion : "0.1.0")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTiny
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "About"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTiny
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: aboutDialog.openDialog()
                        }
                    }
                }
            }
        }

        // --- Main Content Canvas Area ---
        Item {
            width: parent.width - sidebar.width
            height: parent.height

            // Pages Stack
            StackLayout {
                id: mainPagesStack
                anchors.fill: parent
                currentIndex: {
                    if (window.currentPage === "home") return 0;
                    if (window.currentPage === "search") return 1;
                    if (window.currentPage === "playlist") return 2;
                    if (window.currentPage === "batch") return 3;
                    if (window.currentPage === "queue") return 4;
                    if (window.currentPage === "history") return 5;
                    if (window.currentPage === "thumbnail") return 6;
                    if (window.currentPage === "settings") return 7;
                    return 0;
                }

                HomePage {
                    id: homePage
                    onNavigateTo: function(page) { window.currentPage = page; }
                    onSearchRequested: function(q) {
                        window.currentPage = "search";
                        searchPage.setSearchQuery(q);
                    }
                    onPlaylistRequested: function(u) {
                        window.currentPage = "playlist";
                        playlistPage.setPlaylistUrl(u);
                    }
                }

                SearchPage {
                    id: searchPage
                }

                PlaylistPage {
                    id: playlistPage
                }

                BatchPage {
                    id: batchPage
                }

                QueuePage {
                    id: queuePage
                }

                HistoryPage {
                    id: historyPage
                }

                ThumbnailPage {
                    id: thumbnailPage
                }

                SettingsPage {
                    id: settingsPage
                }
            }

            // Global Toast Notification
            Toast {
                id: globalToast
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                z: 100
            }

            // Global Available Formats Dialog
            AvailableFormatsDialog {
                id: availableFormatsDialog
                z: 150
                onFormatChosen: function(vFmt, aFmt) {
                    globalToast.show("Selected format: " + (vFmt || aFmt), "info");
                }
            }

            // Global Confirmation Dialog
            ConfirmDialog {
                id: confirmDialog
                z: 200
            }

            // Global About Dialog
            AboutDialog {
                id: aboutDialog
                z: 250
            }
        }
    }

    // Connect global bridge toasts and notifications
    Connections {
        target: bridge
        function onShowToast(type, msg) {
            globalToast.show(msg, type);
        }
    }
}

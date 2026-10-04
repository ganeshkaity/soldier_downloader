import QtQuick

Item {
    id: root

    property string message: ""
    property string toastType: "info" // "info", "success", "warning", "error"
    property int durationMs: 3500

    signal dismissed()

    implicitWidth: Math.min(toastContent.implicitWidth + 40, 480)
    implicitHeight: 48

    opacity: 0.0
    y: 20

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: Theme.glassCard
        border.color: {
            if (root.toastType === "success") return Theme.statusSuccess;
            if (root.toastType === "error") return Theme.statusError;
            if (root.toastType === "warning") return Theme.statusWarning;
            return Theme.accent;
        }
        border.width: 1

        Row {
            id: toastContent
            anchors.centerIn: parent
            spacing: 12
            leftPadding: 16
            rightPadding: 16

            Text {
                text: {
                    if (root.toastType === "success") return "✓";
                    if (root.toastType === "error") return "✕";
                    if (root.toastType === "warning") return "⚠";
                    return "ℹ";
                }
                color: bg.border.color
                font.pixelSize: 14
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.message
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBody
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: root; property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "y"; to: 0; duration: 200; easing.type: Easing.OutQuad }
    }

    ParallelAnimation {
        id: hideAnim
        NumberAnimation { target: root; property: "opacity"; to: 0.0; duration: 200; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "y"; to: 20; duration: 200; easing.type: Easing.InQuad }
        onFinished: root.dismissed()
    }

    Timer {
        id: dismissTimer
        interval: root.durationMs
        repeat: false
        onTriggered: hideAnim.start()
    }

    function show(msg, type) {
        root.message = msg;
        root.toastType = type || "info";
        showAnim.start();
        dismissTimer.restart();
    }
}

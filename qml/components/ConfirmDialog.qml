import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string title: "Confirm Action"
    property string message: "Are you sure you want to proceed?"
    property string confirmText: "Confirm"
    property string cancelText: "Cancel"
    property string confirmVariant: "destructive"
    property bool isVisible: false

    signal confirmed()
    signal cancelled()

    anchors.fill: parent
    visible: opacity > 0
    opacity: isVisible ? 1.0 : 0.0

    Behavior on opacity { NumberAnimation { duration: 150 } }

    // Backdrop
    Rectangle {
        anchors.fill: parent
        color: Theme.bgOverlay

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancel()
        }
    }

    // Modal Card
    GlassCard {
        id: dialogCard
        width: Math.min(parent.width - 40, 440)
        height: dialogContent.implicitHeight + 48
        anchors.centerIn: parent
        cardColor: Theme.glassCard
        borderColor: Theme.borderHighlight

        Column {
            id: dialogContent
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            Text {
                text: root.title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeHeading
                font.weight: Font.DemiBold
                color: Theme.textPrimary
            }

            Text {
                text: root.message
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBody
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Row {
                anchors.right: parent.right
                spacing: 12
                topPadding: 8

                GlassButton {
                    text: root.cancelText
                    variant: "tertiary"
                    buttonHeight: 36
                    onClicked: root.cancel()
                }

                GlassButton {
                    text: root.confirmText
                    variant: root.confirmVariant
                    buttonHeight: 36
                    onClicked: root.confirm()
                }
            }
        }
    }

    function openDialog(titleText, msgText, onConfirm, variant) {
        root.title = titleText;
        root.message = msgText;
        if (variant) root.confirmVariant = variant;
        root.isVisible = true;
    }

    function confirm() {
        root.isVisible = false;
        root.confirmed();
    }

    function cancel() {
        root.isVisible = false;
        root.cancelled();
    }
}

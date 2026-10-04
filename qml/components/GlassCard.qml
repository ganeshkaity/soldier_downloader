import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property bool interactive: false
    property bool hoverEnabled: interactive
    property bool isHovered: hoverArea.containsMouse
    property color cardColor: Theme.glassCardTranslucent
    property color borderColor: isHovered && interactive ? Theme.borderHighlight : Theme.borderCard
    property int cardRadius: Theme.radiusLarge

    signal clicked()

    color: cardColor
    radius: cardRadius
    border.color: borderColor
    border.width: 1

    Behavior on border.color {
        ColorAnimation { duration: 150 }
    }

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.hoverEnabled
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}

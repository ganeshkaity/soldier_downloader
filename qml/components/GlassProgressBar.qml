import QtQuick

Item {
    id: root

    property real value: 0.0 // 0 to 100
    property color trackColor: Theme.glassCard
    property color fillColor: Theme.accent
    property color gradientEnd: Theme.accentSecondary
    property int barHeight: 8
    property int barRadius: 4

    implicitWidth: 200
    implicitHeight: barHeight

    Rectangle {
        id: track
        anchors.fill: parent
        radius: root.barRadius
        color: root.trackColor
        border.color: Theme.borderSubtle
        border.width: 1
        clip: true

        Rectangle {
            id: fill
            height: parent.height
            radius: root.barRadius
            width: Math.max(0, Math.min(parent.width, parent.width * (root.value / 100.0)))

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root.fillColor }
                GradientStop { position: 1.0; color: root.gradientEnd }
            }

            Behavior on width {
                NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
            }
        }
    }
}

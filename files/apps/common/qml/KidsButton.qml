import QtQuick
import QtQuick.Controls.Basic as Controls
import KidsOS.Theme

// Large, rounded, touch-friendly button. Variants: "primary" (filled brand
// blue), "secondary" (soft surface), "ghost" (text-only, for "Skip" links).
Controls.Button {
    id: root

    property string variant: "primary"
    property bool fullWidth: false

    implicitHeight: Math.max(Theme.touchTargetMin, 56)
    implicitWidth: fullWidth ? (parent ? parent.width : 320) : contentItem.implicitWidth + Theme.spaceXl * 2
    focusPolicy: Qt.StrongFocus

    readonly property color _bg: {
        if (variant === "primary") return down ? Theme.primaryPressed : Theme.primary
        if (variant === "secondary") return down ? Theme.surfaceSunken : Theme.surfaceAlt
        return "transparent"
    }
    readonly property color _fg: variant === "primary" ? Theme.textOnPrimary : Theme.textPrimary

    scale: down ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingStandard } }
    opacity: enabled ? 1.0 : 0.5

    background: Rectangle {
        radius: Theme.radiusPill
        color: root._bg
        border.width: root.variant === "secondary" ? 1 : 0
        border.color: Theme.border

        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

        // Focus ring for keyboard navigation
        Rectangle {
            visible: root.visualFocus
            anchors.fill: parent
            anchors.margins: -4
            radius: parent.radius + 4
            color: "transparent"
            border.width: 3
            border.color: Theme.primary
        }
    }

    contentItem: Text {
        text: root.text
        font.family: Theme.fontInterface
        font.pixelSize: Theme.sizeButton
        font.weight: Font.Medium
        color: root._fg
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}

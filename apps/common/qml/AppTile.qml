import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Effects
import KidsOS.Theme

// Large touch-friendly app tile used on the KidsOS home screen, launcher
// and app grid. Icon language matches branding/icons/: a neutral
// light-gray rounded-square chip, a colored glyph, and a short brand-color
// accent bar — see branding/icons/README.md.
Controls.AbstractButton {
    id: root

    property string label: ""
    property string glyph: "⭐"
    property color tint: Theme.logo.s
    signal activated()
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    onClicked: root.activated()

    implicitWidth: 168
    implicitHeight: 140

    background: Rectangle {
        id: surface
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: root.visualFocus ? 2 : 0
        border.color: Theme.primary
        scale: root.pressed ? 0.95 : (root.hovered ? 1.03 : 1.0)

        Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingStandard } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadowColor
            shadowOpacity: root.hovered ? Theme.shadowOpacityMed : Theme.shadowOpacityLow
            shadowBlur: 0.5
            shadowVerticalOffset: root.hovered ? 6 : 4
        }
    }

    contentItem: Column {
        spacing: Theme.spaceSm

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56; height: 56
            radius: Theme.radiusMd
            color: Theme.iconContainer

            Text { anchors.centerIn: parent; text: root.glyph; font.pixelSize: 26 }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                width: 20; height: 3
                radius: 1.5
                color: root.tint
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeCaption
            font.weight: Font.Medium
            color: Theme.textPrimary
            horizontalAlignment: Text.AlignHCenter
            width: root.width - Theme.spaceMd
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
}

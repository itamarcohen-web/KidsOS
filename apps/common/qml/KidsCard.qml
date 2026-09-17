import QtQuick
import QtQuick.Effects
import KidsOS.Theme

// Reusable elevated surface card used for language cards, avatar tiles,
// app tiles, and dialogs across every KidsOS app.
Rectangle {
    id: root

    property bool selected: false
    property bool interactive: true
    property bool pressed: false

    radius: Theme.radiusLg
    color: selected ? Qt.tint(Theme.primary, "#E6FFFFFF") : Theme.surface
    border.width: selected ? 3 : 1
    border.color: selected ? Theme.primary : Theme.border

    scale: pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingStandard } }
    Behavior on color { ColorAnimation { duration: Theme.durationNormal } }
    Behavior on border.color { ColorAnimation { duration: Theme.durationNormal } }

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.shadowColor
        shadowOpacity: root.selected ? Theme.shadowOpacityMed : Theme.shadowOpacityLow
        shadowBlur: 0.6
        shadowVerticalOffset: 6
    }
}

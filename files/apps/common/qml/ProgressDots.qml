import QtQuick
import KidsOS.Theme

// Onboarding step indicator. Lives inside a RTL-aware parent so the whole
// Row reverses order automatically via LayoutMirroring — no manual flipping.
Row {
    id: root

    property int count: 8
    property int currentIndex: 0

    spacing: Theme.spaceSm

    Repeater {
        model: root.count
        delegate: Rectangle {
            required property int index
            readonly property bool active: index === root.currentIndex
            readonly property bool done: index < root.currentIndex

            width: active ? 28 : 8
            height: 8
            radius: 4
            color: active ? Theme.primary : (done ? Theme.logo.d : Theme.border)

            Behavior on width { NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easingStandard } }
            Behavior on color { ColorAnimation { duration: Theme.durationNormal } }
        }
    }
}

import QtQuick
import KidsOS.Theme

// The KIDS wordmark: four letters, four colors, playful rounded display
// font, each with a small "alive" rotation and baseline offset — per the
// brand reference SVG (see branding/logo/README.md). This is a brand
// mark, not translated UI text — it always reads K-I-D-S left-to-right
// even inside a mirrored RTL layout.
Row {
    id: root

    // "welcome" (huge, used on the welcome screen) or "compact" (app bar / launcher)
    property string variant: "welcome"
    property bool animated: false

    LayoutMirroring.enabled: false
    LayoutMirroring.childrenInherit: false
    // A little extra breathing room than a plain Row would use, so the
    // per-letter rotation never lets two letters visually touch.
    spacing: variant === "welcome" ? Theme.spaceMd : Theme.spaceXs

    readonly property int _letterSize: variant === "welcome" ? Theme.sizeDisplay : Theme.sizeH2
    readonly property real _riseRatio: 5 / 31 // matches the reference SVG's y=76 vs y=71 baselines at font-size 31
    readonly property var _letters: [
        { ch: "K", color: Theme.logo.k, rot: -6, rise: 0 },
        { ch: "I", color: Theme.logo.i, rot: 4, rise: 1 },
        { ch: "D", color: Theme.logo.d, rot: -3, rise: 0 },
        { ch: "S", color: Theme.logo.s, rot: 6, rise: 1 }
    ]

    function playEntrance() {
        for (var i = 0; i < repeater.count; i++) {
            var item = repeater.itemAt(i)
            if (item)
                item.entranceTrigger = !item.entranceTrigger
        }
    }

    Repeater {
        id: repeater
        model: root._letters
        delegate: Text {
            id: letterItem
            required property var modelData
            property bool entranceTrigger: false

            text: modelData.ch
            color: modelData.color
            font.family: Theme.fontDisplay
            font.pixelSize: root._letterSize
            font.weight: Theme.fontDisplayWeight
            font.capitalization: Font.AllUppercase
            rotation: modelData.rot
            y: modelData.rise > 0 ? -(root._riseRatio * root._letterSize) : 0

            opacity: root.animated ? 0 : 1
            scale: root.animated ? 0.4 : 1

            Behavior on opacity {
                enabled: root.animated
                NumberAnimation { duration: Theme.durationSlow; easing.type: Theme.easingStandard }
            }
            Behavior on scale {
                enabled: root.animated
                NumberAnimation { duration: Theme.durationSlow; easing.type: Theme.easingEmphasized }
            }

            onEntranceTriggerChanged: {
                opacity = 1
                scale = 1
            }

            Component.onCompleted: {
                if (root.animated) {
                    entranceTimer.index = index
                    entranceTimer.start()
                }
            }

            Timer {
                id: entranceTimer
                property int index: 0
                interval: 90 * index
                running: false
                repeat: false
                onTriggered: {
                    letterItem.opacity = 1
                    letterItem.scale = 1
                }
            }
        }
    }
}

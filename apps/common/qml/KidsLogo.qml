import QtQuick
import KidsOS.Theme

// The KIDS wordmark: four letters, four colors, playful rounded display
// font. This is a brand mark, not translated UI text — it always reads
// K-I-D-S left-to-right even inside a mirrored RTL layout.
Row {
    id: root

    // "welcome" (huge, used on the welcome screen) or "compact" (app bar / launcher)
    property string variant: "welcome"
    property bool animated: false

    LayoutMirroring.enabled: false
    LayoutMirroring.childrenInherit: false
    spacing: variant === "welcome" ? Theme.spaceXs : 1

    readonly property int _letterSize: variant === "welcome" ? Theme.sizeDisplay : Theme.sizeH2
    readonly property var _letters: [
        { ch: "K", color: Theme.logo.k },
        { ch: "I", color: Theme.logo.i },
        { ch: "D", color: Theme.logo.d },
        { ch: "S", color: Theme.logo.s }
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
            font.weight: Font.DemiBold
            font.capitalization: Font.AllUppercase

            opacity: root.animated ? 0 : 1
            scale: root.animated ? 0.4 : 1
            y: 0

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

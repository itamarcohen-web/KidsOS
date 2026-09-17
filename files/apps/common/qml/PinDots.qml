import QtQuick
import KidsOS.Theme

// Large circular PIN indicators: ● ● ● ●
Row {
    id: root

    property int length: 4
    property int filledCount: 0
    property bool shake: false

    spacing: Theme.spaceLg

    onShakeChanged: if (shake) shakeAnim.start()

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: root; property: "x"; from: 0; to: -14; duration: 45 }
        NumberAnimation { target: root; property: "x"; to: 14; duration: 45 }
        NumberAnimation { target: root; property: "x"; to: -10; duration: 45 }
        NumberAnimation { target: root; property: "x"; to: 10; duration: 45 }
        NumberAnimation { target: root; property: "x"; to: 0; duration: 45 }
        onFinished: root.shake = false
    }

    Repeater {
        model: root.length
        delegate: Rectangle {
            required property int index
            readonly property bool filled: index < root.filledCount

            width: 24; height: 24
            radius: 12
            color: filled ? Theme.primary : "transparent"
            border.width: 2.5
            border.color: filled ? Theme.primary : Theme.border
            scale: filled ? 1.0 : 0.9

            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
            Behavior on scale {
                NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingEmphasized }
            }
        }
    }
}

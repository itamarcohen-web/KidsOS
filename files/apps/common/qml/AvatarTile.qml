import QtQuick
import QtQuick.Controls.Basic as Controls
import KidsOS.Theme

// Keyboard-accessible avatar picker tile: built on AbstractButton so it
// participates in Tab order and responds to Enter/Space, not just touch.
// Selection is externally driven (`selected`), not the button's own
// checked-state machine, since only one tile in the grid may be selected
// at a time and that choice lives in the screen's shared app state.
Controls.AbstractButton {
    id: root

    property string glyph: "\u{1F916}" // emoji fallback glyph, e.g. robot
    property color tint: Theme.logo.s
    property bool selected: false
    focusPolicy: Qt.StrongFocus
    signal activated()
    onClicked: root.activated()

    implicitWidth: 140
    implicitHeight: 160

    background: Item {}

    contentItem: Column {
        spacing: Theme.spaceSm

        Rectangle {
            id: circle
            anchors.horizontalCenter: parent.horizontalCenter
            width: 96; height: 96
            radius: 48
            color: Qt.tint(root.tint, "#CCFFFFFF")
            border.width: root.selected ? 4 : (root.visualFocus ? 3 : 0)
            border.color: root.visualFocus && !root.selected ? Theme.primary : root.tint
            scale: root.pressed ? 0.92 : (root.selected ? 1.06 : 1.0)

            Behavior on scale { NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easingEmphasized } }
            Behavior on border.width { NumberAnimation { duration: Theme.durationFast } }

            Text {
                anchors.centerIn: parent
                text: root.glyph
                font.pixelSize: 44
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.text
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeBody
            font.weight: root.selected ? Font.DemiBold : Font.Normal
            color: root.selected ? Theme.textPrimary : Theme.textSecondary
        }
    }
}

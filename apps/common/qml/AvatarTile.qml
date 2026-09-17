import QtQuick
import KidsOS.Theme

Item {
    id: root

    property string glyph: "\u{1F916}" // emoji fallback glyph, e.g. robot
    property string label: ""
    property color tint: Theme.logo.s
    property bool selected: false
    signal activated()

    implicitWidth: 140
    implicitHeight: 160

    Column {
        anchors.fill: parent
        spacing: Theme.spaceSm

        Rectangle {
            id: circle
            anchors.horizontalCenter: parent.horizontalCenter
            width: 96; height: 96
            radius: 48
            color: Qt.tint(root.tint, "#CCFFFFFF")
            border.width: root.selected ? 4 : 0
            border.color: root.tint
            scale: pressArea.pressed ? 0.92 : (root.selected ? 1.06 : 1.0)

            Behavior on scale { NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easingEmphasized } }
            Behavior on border.width { NumberAnimation { duration: Theme.durationFast } }

            Text {
                anchors.centerIn: parent
                text: root.glyph
                font.pixelSize: 44
            }

            MouseArea {
                id: pressArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activated()
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeBody
            font.weight: root.selected ? Font.DemiBold : Font.Normal
            color: root.selected ? Theme.textPrimary : Theme.textSecondary
        }
    }
}

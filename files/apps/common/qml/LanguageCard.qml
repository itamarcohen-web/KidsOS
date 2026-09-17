import QtQuick
import QtQuick.Controls.Basic as Controls
import KidsOS.Theme

// Keyboard-accessible language picker card (Tab + Enter/Space work, not
// just touch/click).
Controls.AbstractButton {
    id: root

    property string nativeName: ""
    property string flagGlyph: ""
    property bool selected: false
    focusPolicy: Qt.StrongFocus
    signal activated()
    onClicked: root.activated()

    implicitWidth: 220
    implicitHeight: 180

    background: KidsCard {
        selected: root.selected
        pressed: root.pressed
        border.color: root.visualFocus && !root.selected ? Theme.primary : (root.selected ? Theme.primary : Theme.border)
    }

    contentItem: Item {
        Column {
            anchors.centerIn: parent
            spacing: Theme.spaceMd

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.flagGlyph
                font.pixelSize: 44
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.nativeName
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH3
                font.weight: Font.Medium
                color: Theme.textPrimary
            }
        }

        Rectangle {
            visible: root.selected
            width: 28; height: 28
            radius: 14
            color: Theme.success
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Theme.spaceMd
            Text {
                anchors.centerIn: parent
                text: "✓"
                color: "white"
                font.pixelSize: 16
                font.bold: true
            }
        }
    }
}

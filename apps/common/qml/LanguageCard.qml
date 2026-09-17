import QtQuick
import KidsOS.Theme

KidsCard {
    id: root

    property string nativeName: ""
    property string flagGlyph: ""
    signal activated()

    implicitWidth: 220
    implicitHeight: 180

    MouseArea {
        anchors.fill: parent
        onPressed: root.pressed = true
        onReleased: root.pressed = false
        onCanceled: root.pressed = false
        onClicked: root.activated()
        cursorShape: Qt.PointingHandCursor
    }

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

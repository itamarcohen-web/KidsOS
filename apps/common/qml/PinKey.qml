import QtQuick
import KidsOS.Theme

// Single numeric keypad key for PIN entry.
Rectangle {
    id: root

    property string label: "0"
    property bool isAction: false // e.g. delete key
    signal activated()

    width: 76; height: 76
    radius: width / 2
    color: area.pressed ? Theme.surfaceSunken : Theme.surfaceAlt

    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    scale: area.pressed ? 0.93 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingStandard } }

    Text {
        anchors.centerIn: parent
        text: root.label
        font.family: Theme.fontInterface
        font.pixelSize: root.isAction ? Theme.sizeH3 : Theme.sizeH2
        color: Theme.textPrimary
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}

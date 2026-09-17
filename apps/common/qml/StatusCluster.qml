import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization

// Compact Wi-Fi / Bluetooth / volume / battery / clock cluster. Tapping it
// opens Quick Settings — used in both the Dock and the desktop top bar.
Controls.AbstractButton {
    id: root

    property bool wifiConnected: true
    property bool bluetoothEnabled: false
    property int volume: 70
    property real batteryLevel: -1 // -1 = no battery (desktop), else 0..1
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    signal activated()
    onClicked: root.activated()

    implicitWidth: row.implicitWidth + Theme.spaceMd * 2
    implicitHeight: 44

    background: Rectangle {
        radius: Theme.radiusPill
        color: root.hovered || root.visualFocus ? Theme.surfaceAlt : "transparent"
        border.width: root.visualFocus ? 2 : 0
        border.color: Theme.primary
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    contentItem: RowLayout {
        id: row
        spacing: Theme.spaceSm

        Text {
            text: root.wifiConnected ? "\u{1F4F6}" : "\u{1F6Dc}"
            font.pixelSize: 15
            color: Theme.textSecondary
            Controls.ToolTip.visible: false
        }
        Text {
            visible: root.bluetoothEnabled
            text: "\u{1F535}"
            font.pixelSize: 11
            color: Theme.textSecondary
        }
        Text {
            visible: root.batteryLevel >= 0
            text: "\u{1F50B}"
            font.pixelSize: 15
            color: Theme.textSecondary
        }
        Text {
            id: clockText
            text: Qt.formatTime(clockTimer.currentTime, "hh:mm")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeCaption
            font.weight: Font.Medium
            color: Theme.textPrimary
        }

        Timer {
            id: clockTimer
            property date currentTime: new Date()
            interval: 1000
            running: true
            repeat: true
            onTriggered: currentTime = new Date()
        }
    }
}

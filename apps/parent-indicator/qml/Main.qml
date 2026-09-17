import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as Controls
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// Spec §12: the Parent desktop is the normal, unrestricted Plasma
// desktop — this is only a small, subtle always-on-top badge marking
// that the current session is the administrator account, plus a quick
// "Switch user" action. It does not restrict or reshape the Parent's
// desktop in any way.
Window {
    id: window
    visible: true
    width: 190
    height: 48
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"

    Component.onCompleted: {
        // Top-right corner, respecting RTL by mirroring to top-left.
        x = LocalizationManager.isRTL ? 24 : Screen.width - width - 24
        y = 24
    }

    LayoutMirroring.enabled: LocalizationManager.isRTL
    LayoutMirroring.childrenInherit: true

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusPill
        color: Theme.isDark ? "#DD1E212E" : "#DDFFFFFF"
        border.width: 1
        border.color: Theme.border

        Controls.AbstractButton {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Bridge.switchUser()

            contentItem: Row {
                anchors.centerIn: parent
                spacing: Theme.spaceSm

                KidsLogo { variant: "compact"; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: LocalizationManager.tr("parentMode.label")
                    font.family: Theme.fontInterface
                    font.pixelSize: Theme.sizeCaption
                    font.weight: Font.Medium
                    color: Theme.textSecondary
                }
            }
        }
    }
}

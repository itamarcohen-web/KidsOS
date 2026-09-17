import QtQuick
import QtQuick.Window
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// Spec §17: shown instead of executing when a child opens a
// downloaded-outside-Kids-Store file. This dialog is a convenience —
// the real block is fapolicyd (see docs/TRUST_MODEL.md), so even if
// this dialog is somehow bypassed, execution still fails.
Window {
    id: window
    visible: true
    width: 440
    height: 340
    minimumWidth: 440
    minimumHeight: 340
    maximumWidth: 440
    maximumHeight: 340
    color: Theme.background
    title: LocalizationManager.tr("fileGuard.title")
    flags: Qt.Dialog

    LayoutMirroring.enabled: LocalizationManager.isRTL
    LayoutMirroring.childrenInherit: true

    property bool submitted: false

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.spaceXxl
        spacing: Theme.spaceLg

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 72; height: 72
            radius: 36
            color: Qt.tint(Theme.logo.k, "#CCFFFFFF")
            Text { anchors.centerIn: parent; text: "\u{1F512}"; font.pixelSize: 32 }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: window.submitted ? LocalizationManager.tr("fileGuard.sentTitle")
                                    : LocalizationManager.tr("fileGuard.title")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH2
            font.weight: Font.DemiBold
            color: Theme.textPrimary
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
            wrapMode: Text.WordWrap
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: window.submitted
                  ? LocalizationManager.tr("fileGuard.sentBody")
                  : LocalizationManager.tr("fileGuard.body", [Bridge.fileName])
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeBody
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
            wrapMode: Text.WordWrap
        }

        KidsButton {
            anchors.horizontalCenter: parent.horizontalCenter
            text: window.submitted ? LocalizationManager.tr("common.close")
                                    : LocalizationManager.tr("fileGuard.askParent")
            fullWidth: true
            width: 280
            onClicked: {
                if (window.submitted) {
                    Qt.quit()
                } else {
                    Bridge.submitRequest()
                    window.submitted = true
                }
            }
        }
    }
}

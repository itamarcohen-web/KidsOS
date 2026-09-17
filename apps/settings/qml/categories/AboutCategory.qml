import QtQuick
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

Item {
    Column {
        anchors.centerIn: parent
        spacing: Theme.spaceLg

        KidsLogo {
            anchors.horizontalCenter: parent.horizontalCenter
            variant: "welcome"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: LocalizationManager.tr("settings.about.version") + " 0.2.0"
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeBody
            color: Theme.textSecondary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: LocalizationManager.tr("settings.about.tagline")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeCaption
            color: Theme.textSecondary
        }
    }
}

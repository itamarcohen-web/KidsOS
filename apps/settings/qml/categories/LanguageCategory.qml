import QtQuick
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// Fully functional: switches the whole running app (and, via
// LocalizationManager, every other KidsOS app that re-reads it) between
// English, Hebrew and Arabic immediately, including RTL mirroring.
Item {
    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.spaceXl

        Text {
            text: LocalizationManager.tr("settings.categories.language")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH1
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }

        Row {
            spacing: Theme.spaceLg
            Repeater {
                model: LocalizationManager.supportedLanguages
                delegate: LanguageCard {
                    required property var modelData
                    nativeName: modelData.nativeName
                    flagGlyph: ({ en: "A", he: "א", ar: "أ" })[modelData.code]
                    selected: LocalizationManager.language === modelData.code
                    onActivated: LocalizationManager.setLanguage(modelData.code)
                }
            }
        }
    }
}

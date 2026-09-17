import QtQuick
import QtQuick.Controls.Basic as Controls
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

OnboardingPage {
    id: page
    required property QtObject appState
    primaryText: LocalizationManager.tr("common.next")
    primaryEnabled: page.appState.language.length > 0
    onBack: Controls.StackView.view.goBack()
    onPrimaryActivated: Controls.StackView.view.goToStep(page.stepIndex + 1)

    readonly property var glyphs: ({ "en": "A", "he": "א", "ar": "أ" })
    readonly property var glyphColors: ({ "en": Theme.logo.s, "he": Theme.logo.k, "ar": Theme.logo.d })

    Column {
        anchors.fill: parent
        spacing: Theme.spaceXxl

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceSm
            topPadding: Theme.spaceXxl

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.language.title")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH1
                font.weight: Font.DemiBold
                color: Theme.textPrimary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.language.subtitle")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeBody
                color: Theme.textSecondary
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceLg

            Repeater {
                model: LocalizationManager.supportedLanguages
                delegate: LanguageCard {
                    required property var modelData
                    nativeName: modelData.nativeName
                    flagGlyph: page.glyphs[modelData.code]
                    selected: page.appState.language === modelData.code

                    onActivated: {
                        page.appState.language = modelData.code
                        LocalizationManager.setLanguage(modelData.code)
                    }
                }
            }
        }
    }
}

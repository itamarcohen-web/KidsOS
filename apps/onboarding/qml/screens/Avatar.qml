import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

OnboardingPage {
    id: page
    required property QtObject appState
    primaryEnabled: page.appState.avatarId.length > 0
    onBack: Controls.StackView.view.goBack()
    onPrimaryActivated: Controls.StackView.view.goToStep(page.stepIndex + 1)

    readonly property var avatars: [
        { id: "robot", glyph: "\u{1F916}", key: "robot", color: Theme.logo.s },
        { id: "cat", glyph: "\u{1F431}", key: "cat", color: Theme.logo.k },
        { id: "dog", glyph: "\u{1F436}", key: "dog", color: Theme.logo.i },
        { id: "astronaut", glyph: "\u{1F9D1}‍\u{1F680}", key: "astronaut", color: Theme.logo.d },
        { id: "football", glyph: "⚽", key: "football", color: "#A66BFF" },
        { id: "music", glyph: "\u{1F3B5}", key: "music", color: "#FF7EB6" },
        { id: "gaming", glyph: "\u{1F3AE}", key: "gaming", color: Theme.logo.s },
        { id: "space", glyph: "\u{1F30C}", key: "space", color: Theme.logo.k },
        { id: "art", glyph: "\u{1F3A8}", key: "art", color: Theme.logo.i },
        { id: "nature", glyph: "\u{1F343}", key: "nature", color: Theme.logo.d }
    ]

    Column {
        anchors.fill: parent
        spacing: Theme.spaceXl

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceSm
            topPadding: Theme.spaceLg

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.avatar.title")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH1
                font.weight: Font.DemiBold
                color: Theme.textPrimary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.avatar.subtitle")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeBody
                color: Theme.textSecondary
            }
        }

        GridLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 5
            columnSpacing: Theme.spaceLg
            rowSpacing: Theme.spaceLg

            Repeater {
                model: page.avatars
                delegate: AvatarTile {
                    required property var modelData
                    glyph: modelData.glyph
                    label: LocalizationManager.tr("onboarding.avatar." + modelData.key)
                    tint: modelData.color
                    selected: page.appState.avatarId === modelData.id
                    onActivated: {
                        page.appState.avatarId = modelData.id
                        page.appState.avatarGlyph = modelData.glyph
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls.Basic as Controls
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

OnboardingPage {
    id: page
    required property QtObject appState
    primaryEnabled: nameField.text.trim().length > 0 && Bridge.isValidUsername(usernameField.text)
    onBack: Controls.StackView.view.goBack()
    onPrimaryActivated: {
        page.appState.name = nameField.text.trim()
        page.appState.username = usernameField.text
        Controls.StackView.view.goToStep(page.stepIndex + 1)
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.7, 560)
        spacing: Theme.spaceXxl

        Text {
            // Marks the start of the "child profile" phase (Name → Avatar
            // → Age → PIN) — spec §5's "Now let's set up your child's
            // space" moment.
            anchors.horizontalCenter: parent.horizontalCenter
            text: LocalizationManager.tr("onboarding.name.childIntro")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeBody
            font.weight: Font.Medium
            color: Theme.logo.k
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: LocalizationManager.tr("onboarding.name.title")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH1
            font.weight: Font.DemiBold
            color: Theme.textPrimary
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            width: parent.width
            height: 84
            radius: Theme.radiusLg
            color: Theme.surface
            border.width: nameField.activeFocus ? 3 : 1
            border.color: nameField.activeFocus ? Theme.primary : Theme.border

            Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

            Controls.TextField {
                id: nameField
                anchors.fill: parent
                anchors.margins: Theme.spaceMd
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: LocalizationManager.isRTL ? Text.AlignRight : Text.AlignLeft
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH2
                color: Theme.textPrimary
                placeholderText: LocalizationManager.tr("onboarding.name.placeholder")
                background: Item {}
                focus: true
                onTextChanged: if (!usernameField.editedManually) usernameField.text = Bridge.suggestUsername(text)
                Keys.onReturnPressed: usernameField.forceActiveFocus()
            }
        }

        Rectangle {
            width: parent.width
            height: 64
            radius: Theme.radiusLg
            color: Theme.surface
            border.width: usernameField.activeFocus ? 3 : 1
            border.color: usernameField.activeFocus ? Theme.primary : Theme.border
            Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

            Controls.TextField {
                id: usernameField
                property bool editedManually: false
                anchors.fill: parent
                anchors.margins: Theme.spaceMd
                verticalAlignment: Text.AlignVCenter
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeBody
                color: Theme.textPrimary
                placeholderText: LocalizationManager.tr("onboarding.name.usernamePlaceholder")
                background: Item {}
                onTextEdited: editedManually = true
                Keys.onReturnPressed: if (page.primaryEnabled) page.primaryActivated()
            }
        }

        Text {
            id: greetingText
            anchors.horizontalCenter: parent.horizontalCenter
            text: nameField.text.trim().length > 0
                  ? LocalizationManager.tr("onboarding.name.greeting", [nameField.text.trim()])
                  : LocalizationManager.tr("onboarding.name.greetingEmpty")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH3
            color: Theme.logo.s
            opacity: 0.9

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: greetingText; property: "opacity"; to: 0; duration: Theme.durationFast }
                    PropertyAction { target: greetingText; property: "text" }
                    NumberAnimation { target: greetingText; property: "opacity"; to: 0.9; duration: Theme.durationFast }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls.Basic as Controls
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// Collects the Parent's display name + username. The password is
// collected on the next screen (ParentPassword.qml) — the account isn't
// actually created (via kidsos-auth) until both are in hand, since
// CreateParentAccount needs all three at once. See
// docs/ACCOUNTS_AND_LOGIN.md.
OnboardingPage {
    id: page
    required property QtObject appState
    primaryEnabled: nameField.text.trim().length > 0 && Bridge.isValidUsername(usernameField.text)
    onBack: Controls.StackView.view.goBack()
    onPrimaryActivated: {
        page.appState.parentName = nameField.text.trim()
        page.appState.parentUsername = usernameField.text
        Controls.StackView.view.goToStep(page.stepIndex + 1)
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.7, 560)
        spacing: Theme.spaceXl

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.parentAccount.title")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH1
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.parentAccount.subtitle")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeBody
                color: Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        Rectangle {
            width: parent.width
            height: 72
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
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH3
                color: Theme.textPrimary
                placeholderText: LocalizationManager.tr("onboarding.parentAccount.namePlaceholder")
                background: Item {}
                focus: true
                onTextChanged: if (!usernameField.editedManually) usernameField.text = Bridge.suggestUsername(text)
            }
        }

        Rectangle {
            width: parent.width
            height: 72
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
                font.pixelSize: Theme.sizeH3
                color: Theme.textPrimary
                placeholderText: LocalizationManager.tr("onboarding.parentAccount.usernamePlaceholder")
                background: Item {}
                onTextEdited: editedManually = true
            }
        }
    }
}

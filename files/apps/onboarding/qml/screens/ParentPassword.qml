import QtQuick
import QtQuick.Controls.Basic as Controls
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// Collects and confirms the Parent's real Linux login password, then
// calls kidsos-auth::CreateParentAccount over D-Bus (OnboardingBridge)
// — this is the actual system administrator credential, not a
// KidsOS-only password. See docs/SECURITY_ARCHITECTURE.md §3-4.
OnboardingPage {
    id: page
    required property QtObject appState
    property bool submitting: false
    property string errorText: ""

    primaryText: submitting ? LocalizationManager.tr("onboarding.parentPassword.creating")
                             : LocalizationManager.tr("common.next")
    primaryEnabled: !submitting && passwordField.text.length >= 8
                    && passwordField.text === confirmField.text
    onBack: Controls.StackView.view.goBack()
    onPrimaryActivated: {
        page.submitting = true
        page.errorText = ""
        // Bridge.createParentAccount is a synchronous D-Bus call (see
        // OnboardingBridge.cpp) — useradd+chpasswd are fast enough in
        // practice that this doesn't visibly hang, but the "Creating
        // account…" primaryText below won't actually repaint before
        // this call returns, since nothing yields to the event loop in
        // between. Acceptable for a one-time setup action; a future
        // pass could make this async if it proves too rough in QA.
        const ok = Bridge.createParentAccount(page.appState.parentName, page.appState.parentUsername,
                                               passwordField.text)
        page.submitting = false
        if (ok) {
            passwordField.text = ""
            confirmField.text = ""
            Controls.StackView.view.goToStep(page.stepIndex + 1)
        } else {
            page.errorText = LocalizationManager.tr("onboarding.parentPassword.error")
        }
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.7, 480)
        spacing: Theme.spaceXl

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.parentPassword.title")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH1
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.parentPassword.subtitle")
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
            border.width: passwordField.activeFocus ? 3 : 1
            border.color: passwordField.activeFocus ? Theme.primary : Theme.border
            Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

            Controls.TextField {
                id: passwordField
                anchors.fill: parent
                anchors.margins: Theme.spaceMd
                verticalAlignment: Text.AlignVCenter
                echoMode: TextInput.Password
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH3
                color: Theme.textPrimary
                placeholderText: LocalizationManager.tr("onboarding.parentPassword.placeholder")
                background: Item {}
                focus: true
            }
        }

        Rectangle {
            width: parent.width
            height: 72
            radius: Theme.radiusLg
            color: Theme.surface
            border.width: confirmField.activeFocus ? 3 : 1
            border.color: confirmField.activeFocus ? Theme.primary : Theme.border
            Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

            Controls.TextField {
                id: confirmField
                anchors.fill: parent
                anchors.margins: Theme.spaceMd
                verticalAlignment: Text.AlignVCenter
                echoMode: TextInput.Password
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH3
                color: Theme.textPrimary
                placeholderText: LocalizationManager.tr("onboarding.parentPassword.confirmPlaceholder")
                background: Item {}
                Keys.onReturnPressed: if (page.primaryEnabled) page.primaryActivated()
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: page.errorText.length > 0
            text: page.errorText
            color: Theme.error
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeCaption
        }
    }
}

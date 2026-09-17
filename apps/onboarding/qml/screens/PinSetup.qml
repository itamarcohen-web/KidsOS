import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// Child device PIN only. This is deliberately separate from any future
// Parent PIN / parent-authentication system (see docs/ROADMAP.md) — a
// child never sees or sets a parent credential from this screen.
OnboardingPage {
    id: page
    required property QtObject appState
    showPrimary: false
    onBack: Controls.StackView.view.goBack()

    // Physical keyboard digits work directly, in addition to tapping the
    // on-screen keypad — no need to tab through twelve tiny buttons.
    Keys.onPressed: function (event) {
        if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            page.digitPressed(String(event.key - Qt.Key_0))
            event.accepted = true
        } else if (event.key === Qt.Key_Backspace) {
            page.backspace()
            event.accepted = true
        }
    }

    property bool confirming: false
    property bool submitting: false
    property string firstPin: ""
    property string currentEntry: ""
    property string errorText: ""

    function digitPressed(d) {
        if (currentEntry.length >= 4)
            return
        currentEntry += d
        if (currentEntry.length === 4)
            completeTimer.start()
    }

    function backspace() {
        if (currentEntry.length > 0)
            currentEntry = currentEntry.slice(0, -1)
    }

    Timer {
        id: completeTimer
        interval: 220
        onTriggered: page.evaluateEntry()
    }

    function evaluateEntry() {
        page.errorText = ""
        if (!confirming) {
            firstPin = currentEntry
            currentEntry = ""
            confirming = true
        } else if (currentEntry !== firstPin) {
            pinDots.shake = true
            currentEntry = ""
            confirming = false
            firstPin = ""
        } else {
            // All child profile fields (name/username/avatar/age) were
            // collected on the previous three screens; this is where
            // they, plus the PIN just confirmed, actually create the
            // real Linux child account via kidsos-auth — see
            // docs/ACCOUNTS_AND_LOGIN.md.
            page.submitting = true
            const ok = Bridge.createChildAccount(page.appState.name, page.appState.username,
                                                  firstPin, page.appState.avatarId, page.appState.age)
            page.submitting = false
            if (ok) {
                Controls.StackView.view.goToStep(page.stepIndex + 1)
            } else {
                page.errorText = LocalizationManager.tr("onboarding.pin.accountError")
                currentEntry = ""
                confirming = false
                firstPin = ""
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: Theme.spaceXxl

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceSm
            topPadding: Theme.spaceLg

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.confirming
                      ? LocalizationManager.tr("onboarding.pin.confirmTitle")
                      : LocalizationManager.tr("onboarding.pin.title")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH1
                font.weight: Font.DemiBold
                color: Theme.textPrimary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.confirming
                      ? LocalizationManager.tr("onboarding.pin.confirmSubtitle")
                      : LocalizationManager.tr("onboarding.pin.subtitle")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeBody
                color: Theme.textSecondary
            }
        }

        PinDots {
            id: pinDots
            anchors.horizontalCenter: parent.horizontalCenter
            length: 4
            filledCount: page.currentEntry.length
        }

        GridLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 3
            rowSpacing: Theme.spaceMd
            columnSpacing: Theme.spaceMd

            Repeater {
                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
                delegate: PinKey {
                    required property string modelData
                    label: modelData
                    onActivated: page.digitPressed(modelData)
                }
            }

            Item { Layout.preferredWidth: 76; Layout.preferredHeight: 76 }
            PinKey {
                label: "0"
                onActivated: page.digitPressed("0")
            }
            PinKey {
                label: "⌫"
                isAction: true
                onActivated: page.backspace()
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

import QtQuick
import QtQuick.Controls.Basic as Controls
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// PLACEHOLDER screen: no real networking or QR generation. It only mocks
// the pairing UX so the flow feels complete; the real Parent Cloud pairing
// protocol is out of scope for this milestone (see docs/ROADMAP.md).
OnboardingPage {
    id: page
    required property QtObject appState
    primaryText: connected ? LocalizationManager.tr("common.next")
                            : LocalizationManager.tr("onboarding.parent.waiting")
    primaryEnabled: connected
    secondaryText: connected ? "" : LocalizationManager.tr("onboarding.parent.skip")
    onBack: Controls.StackView.view.goBack()
    onPrimaryActivated: Controls.StackView.view.goToStep(page.stepIndex + 1)
    onSecondaryActivated: Controls.StackView.view.goToStep(page.stepIndex + 1)

    property bool connected: false
    readonly property string pairingCode: "482 913"

    Column {
        anchors.fill: parent
        spacing: Theme.spaceXl

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceSm
            topPadding: Theme.spaceLg

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.parent.title")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH1
                font.weight: Font.DemiBold
                color: Theme.textPrimary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.parent.subtitle")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeBody
                color: Theme.textSecondary
            }
        }

        Rectangle {
            id: qrBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 220; height: 220
            radius: Theme.radiusLg
            color: Theme.surface
            border.width: 2
            border.color: Theme.border

            scale: qrArea.pressed ? 0.97 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.durationFast } }

            // Stylized QR placeholder: finder-pattern corners + a randomized
            // module grid. Not a scannable QR code — purely decorative UX.
            Grid {
                anchors.centerIn: parent
                columns: 7
                rows: 7
                spacing: 4
                Repeater {
                    model: 49
                    delegate: Rectangle {
                        required property int index
                        readonly property int col: index % 7
                        readonly property int row: Math.floor(index / 7)
                        readonly property bool isCorner: (col < 2 && row < 2) || (col > 4 && row < 2) || (col < 2 && row > 4)
                        width: 20; height: 20
                        radius: 3
                        color: isCorner || ((col * 7 + row) % 3 === 0) ? Theme.textPrimary : "transparent"
                    }
                }
            }

            MouseArea {
                id: qrArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !page.connected
                onClicked: connectSequence.start()
            }

            // Gentle pulsing ring while waiting — communicates "listening".
            Rectangle {
                visible: !page.connected
                anchors.centerIn: parent
                width: parent.width + 16
                height: parent.height + 16
                radius: Theme.radiusLg + 8
                color: "transparent"
                border.width: 2
                border.color: Theme.primary
                opacity: 0.5

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: !page.connected
                    NumberAnimation { to: 0.05; duration: Theme.durationSlow * 2; easing.type: Theme.easingStandard }
                    NumberAnimation { to: 0.5; duration: Theme.durationSlow * 2; easing.type: Theme.easingStandard }
                }
            }

            // Success check, shown once "connected".
            Rectangle {
                visible: page.connected
                anchors.centerIn: parent
                width: 72; height: 72
                radius: 36
                color: Theme.success
                opacity: page.connected ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.durationNormal } }
                Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 32; font.bold: true }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceXs
            visible: !page.connected

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.parent.pairingCodeLabel")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeCaption
                color: Theme.textSecondary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.pairingCode
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH2
                font.weight: Font.DemiBold
                font.letterSpacing: 4
                color: Theme.textPrimary
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: page.connected
            text: LocalizationManager.tr("onboarding.parent.connected")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH3
            color: Theme.success
        }
    }

    // Mocked successful pairing flow, for development only.
    SequentialAnimation {
        id: connectSequence
        PauseAnimation { duration: 900 }
        ScriptAction { script: page.connected = true }
    }
}

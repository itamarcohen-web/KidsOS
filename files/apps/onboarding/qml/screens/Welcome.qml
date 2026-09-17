import QtQuick
import QtQuick.Controls.Basic as Controls
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

Item {
    id: root
    required property QtObject appState
    required property int stepIndex
    property int stepCount: 0 // unused on this screen (no progress dots) — see Main.qml's goToStep

    Rectangle { anchors.fill: parent; color: Theme.background }

    // Soft decorative color blobs — subtle, not distracting.
    Rectangle {
        width: 420; height: 420; radius: 210
        color: Theme.logo.s
        opacity: 0.10
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -260
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -160
    }
    Rectangle {
        width: 360; height: 360; radius: 180
        color: Theme.logo.k
        opacity: 0.10
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 300
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 220
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.spaceXl
        width: Math.min(parent.width * 0.8, 720)

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.welcome.title1")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH1
                font.weight: Font.Medium
                color: Theme.textSecondary
            }

            KidsLogo {
                id: logo
                anchors.horizontalCenter: parent.horizontalCenter
                variant: "welcome"
                animated: true
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: LocalizationManager.tr("onboarding.welcome.subtitle")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeBodyLarge
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            width: parent.width
        }

        KidsButton {
            anchors.horizontalCenter: parent.horizontalCenter
            text: LocalizationManager.tr("onboarding.welcome.cta")
            width: 280
            fullWidth: true
            onClicked: Controls.StackView.view.goToStep(root.stepIndex + 1)

            Behavior on opacity { NumberAnimation { duration: Theme.durationSlow } }
        }
    }

    Component.onCompleted: entranceTimer.start()
    Timer { id: entranceTimer; interval: 120; onTriggered: logo.playEntrance() }
}

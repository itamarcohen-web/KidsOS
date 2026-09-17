import QtQuick
import QtQuick.Controls.Basic as Controls
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

OnboardingPage {
    id: page
    required property QtObject appState
    showBack: false
    showProgress: false
    primaryText: LocalizationManager.tr("onboarding.finish.cta")
    onPrimaryActivated: {
        // Disables the kidsos-setup autologin (see AuthService::
        // MarkFirstBootComplete) — quitting then ends this app, which
        // is the entire kidsos-setup X session's content
        // (recipes/files/usr/share/xsessions/kidsos-setup.desktop), so
        // the session ends and SDDM shows the real KidsOS login screen
        // with the two accounts just created. See
        // docs/ACCOUNTS_AND_LOGIN.md.
        Bridge.markFirstBootComplete()
        Qt.quit()
    }

    Component.onCompleted: confettiTimer.start()
    Timer { id: confettiTimer; interval: 150; onTriggered: confetti.burst() }

    Column {
        anchors.centerIn: parent
        spacing: Theme.spaceXl
        width: Math.min(parent.width * 0.8, 640)

        Rectangle {
            id: successBadge
            anchors.horizontalCenter: parent.horizontalCenter
            width: 120; height: 120
            radius: 60
            color: Theme.success
            scale: 0
            Component.onCompleted: scaleAnim.start()
            NumberAnimation { id: scaleAnim; target: successBadge; property: "scale"; to: 1; duration: Theme.durationSlow; easing.type: Theme.easingEmphasized }

            Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 56; font.bold: true }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: LocalizationManager.tr("onboarding.finish.title")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH1
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: LocalizationManager.tr("onboarding.finish.subtitle")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeBodyLarge
            color: Theme.textSecondary
        }
    }

    // Lightweight confetti burst using the brand palette.
    Item {
        id: confetti
        anchors.fill: parent
        z: 10

        function burst() {
            for (var i = 0; i < 24; i++)
                confettiComponent.createObject(confetti, {
                    "x": confetti.width / 2,
                    "y": confetti.height / 3,
                    "targetX": Math.random() * confetti.width,
                    "targetY": confetti.height * (0.6 + Math.random() * 0.4),
                    "pieceColor": [Theme.logo.k, Theme.logo.i, Theme.logo.d, Theme.logo.s][i % 4]
                })
        }

        Component {
            id: confettiComponent
            Rectangle {
                property real targetX: 0
                property real targetY: 0
                property color pieceColor: Theme.logo.s
                width: 10; height: 10
                radius: 2
                color: pieceColor
                rotation: Math.random() * 360

                NumberAnimation on x { to: targetX; duration: 900 + Math.random() * 400; easing.type: Easing.OutCubic }
                NumberAnimation on y { to: targetY; duration: 900 + Math.random() * 400; easing.type: Easing.OutCubic }
                NumberAnimation on opacity { to: 0; duration: 1200; onFinished: destroy() }
                NumberAnimation on rotation { to: rotation + 180; duration: 1200 }
            }
        }
    }
}

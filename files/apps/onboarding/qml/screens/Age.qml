import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

OnboardingPage {
    id: page
    required property QtObject appState
    primaryEnabled: page.appState.age > 0
    onBack: Controls.StackView.view.goBack()
    onPrimaryActivated: Controls.StackView.view.goToStep(page.stepIndex + 1)

    readonly property var ages: [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]

    Column {
        anchors.fill: parent
        spacing: Theme.spaceXxl

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceSm
            topPadding: Theme.spaceXxl

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.age.title")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH1
                font.weight: Font.DemiBold
                color: Theme.textPrimary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("onboarding.age.subtitle")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeBody
                color: Theme.textSecondary
            }
        }

        GridLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 6
            columnSpacing: Theme.spaceMd
            rowSpacing: Theme.spaceMd

            Repeater {
                model: page.ages
                delegate: Controls.AbstractButton {
                    id: ageButton
                    required property int modelData
                    readonly property bool selected: page.appState.age === modelData
                    focusPolicy: Qt.StrongFocus
                    onClicked: page.appState.age = modelData

                    implicitWidth: 84
                    implicitHeight: 84

                    background: Rectangle {
                        radius: Theme.radiusLg
                        color: ageButton.selected ? Theme.primary : Theme.surface
                        border.width: ageButton.selected ? 0 : (ageButton.visualFocus ? 2 : 1)
                        border.color: ageButton.visualFocus && !ageButton.selected ? Theme.primary : Theme.border
                        scale: ageButton.pressed ? 0.93 : 1.0

                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                        Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingEmphasized } }
                    }

                    contentItem: Text {
                        text: ageButton.modelData
                        font.family: Theme.fontInterface
                        font.pixelSize: Theme.sizeH2
                        font.weight: Font.DemiBold
                        color: ageButton.selected ? Theme.textOnPrimary : Theme.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}

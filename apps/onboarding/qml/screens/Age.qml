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
                delegate: Rectangle {
                    required property int modelData
                    width: 84; height: 84
                    radius: Theme.radiusLg
                    readonly property bool selected: page.appState.age === modelData

                    color: selected ? Theme.primary : Theme.surface
                    border.width: selected ? 0 : 1
                    border.color: Theme.border
                    scale: ageArea.pressed ? 0.93 : 1.0

                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingEmphasized } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.fontInterface
                        font.pixelSize: Theme.sizeH2
                        font.weight: Font.DemiBold
                        color: selected ? Theme.textOnPrimary : Theme.textPrimary
                    }

                    MouseArea {
                        id: ageArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.appState.age = modelData
                    }
                }
            }
        }
    }
}

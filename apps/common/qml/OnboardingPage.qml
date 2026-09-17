import QtQuick
import KidsOS.Theme
import KidsOS.Localization

// Shared full-screen scaffold for every onboarding step: back button, step
// dots, a content slot, and a primary/secondary action footer. Keeps every
// screen visually and behaviorally consistent, and centralizes the RTL /
// reduced-motion / keyboard-navigation handling in one place.
FocusScope {
    id: root

    property int stepIndex: 0
    property int stepCount: 8
    property bool showBack: true
    property bool showProgress: true

    property string primaryText: LocalizationManager.tr("common.next")
    property bool primaryEnabled: true
    property bool showPrimary: true
    property string secondaryText: ""

    default property alias content: contentArea.children

    signal back()
    signal primaryActivated()
    signal secondaryActivated()

    Keys.onEscapePressed: if (root.showBack) root.back()
    Keys.onReturnPressed: if (root.primaryEnabled) root.primaryActivated()
    Keys.onEnterPressed: if (root.primaryEnabled) root.primaryActivated()

    // Entrance animation: gentle fade + rise, respects reduced motion.
    opacity: 0
    y: Theme.reducedMotion ? 0 : 24
    Component.onCompleted: {
        opacity = 1
        y = 0
        root.forceActiveFocus()
    }
    Behavior on opacity { NumberAnimation { duration: Theme.durationPage; easing.type: Theme.easingStandard } }
    Behavior on y { NumberAnimation { duration: Theme.durationPage; easing.type: Theme.easingStandard } }

    Rectangle { anchors.fill: parent; color: Theme.background }

    // ---- Header: back button + progress dots ----
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spaceXl
        height: 48

        Rectangle {
            id: backButton
            visible: root.showBack
            width: 48; height: 48
            radius: 24
            color: backArea.pressed ? Theme.surfaceSunken : Theme.surfaceAlt
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: LocalizationManager.isRTL ? "→" : "←"
                font.pixelSize: 20
                color: Theme.textPrimary
            }
            MouseArea {
                id: backArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.back()
            }
        }

        ProgressDots {
            visible: root.showProgress
            anchors.centerIn: parent
            count: root.stepCount
            currentIndex: root.stepIndex
        }
    }

    // ---- Main content slot ----
    Item {
        id: contentArea
        anchors.top: header.bottom
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spaceXl
    }

    // ---- Footer: primary action + optional secondary link ----
    Column {
        id: footer
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Theme.spaceXxl
        spacing: Theme.spaceMd

        KidsButton {
            visible: root.showPrimary
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.primaryText
            enabled: root.primaryEnabled
            width: 320
            fullWidth: true
            onClicked: root.primaryActivated()
        }

        KidsButton {
            visible: root.secondaryText.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.secondaryText
            variant: "ghost"
            onClicked: root.secondaryActivated()
        }
    }
}

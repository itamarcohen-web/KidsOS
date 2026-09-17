import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as Controls
import KidsOS.Theme
import KidsOS.Localization

Window {
    id: window
    visible: true
    visibility: Window.FullScreen
    color: Theme.background
    title: "KIDS"

    LayoutMirroring.enabled: LocalizationManager.isRTL
    LayoutMirroring.childrenInherit: true

    // Shared, mutable draft of everything the child picks during setup.
    // Passed into every pushed screen as `appState` (see StackView.push
    // calls below) rather than a global singleton, to keep this app
    // self-contained and easy to reason about.
    QtObject {
        id: appState
        property string language: "en"

        // Parent account draft (spec §2-4). The password is held only
        // in memory for the few seconds between the password screen and
        // the CreateParentAccount D-Bus call, then screens should not
        // read it back — see screens/ParentPassword.qml.
        property string parentName: ""
        property string parentUsername: ""

        // Child profile draft (spec §5-6).
        property string name: ""
        property string username: ""
        property string avatarId: ""
        property string avatarGlyph: ""
        property int age: 0
    }

    readonly property var screenUrls: [
        "screens/Welcome.qml",
        "screens/Language.qml",
        "screens/ParentAccount.qml",
        "screens/ParentPassword.qml",
        "screens/Name.qml",
        "screens/Avatar.qml",
        "screens/Age.qml",
        "screens/PinSetup.qml",
        "screens/ParentConnect.qml",
        "screens/Finish.qml"
    ]

    Controls.StackView {
        id: stack
        anchors.fill: parent

        // Screens call these instead of manipulating the StackView directly,
        // so navigation stays declarative and step index bookkeeping is
        // centralized in one place.
        function goToStep(index) {
            if (index < 0 || index >= window.screenUrls.length)
                return
            stack.push(Qt.resolvedUrl(window.screenUrls[index]), {
                "appState": appState,
                "stepIndex": index,
                "stepCount": window.screenUrls.length
            })
        }

        function goBack() {
            if (stack.depth > 1)
                stack.pop()
        }

        pushEnter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationPage }
        }
        pushExit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationPage }
        }
        popEnter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationPage }
        }
        popExit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationPage }
        }
    }

    Component.onCompleted: stack.goToStep(0)
}

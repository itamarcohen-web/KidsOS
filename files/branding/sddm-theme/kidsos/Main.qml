import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// KidsOS login screen. Card-based account picker → credential entry,
// matching every other KidsOS app's visual language (imports the same
// KidsOS.Theme/Common modules — see recipes/files/etc/sddm.conf.d/
// kidsos-theme.conf's GreeterEnvironment for how the greeter process
// gets QML2_IMPORT_PATH). `sddm`/`userModel`/`sessionModel` are SDDM's
// own QML greeter API (not a KidsOS invention) — see
// docs/ACCOUNTS_AND_LOGIN.md.
Item {
    id: root
    width: Screen.width
    height: Screen.height

    LayoutMirroring.enabled: LocalizationManager.isRTL
    LayoutMirroring.childrenInherit: true

    property int selectedIndex: -1
    property string selectedUsername: ""
    property var selectedProfile: ({ role: "child", avatarId: "", displayName: "" })
    property string errorText: ""

    function profileFor(username, callback) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///var/lib/kidsos/profiles/" + username + ".json")
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try { callback(JSON.parse(xhr.responseText)) }
                    catch (e) { callback({ role: "child", avatarId: "", displayName: username }) }
                } else {
                    callback({ role: "child", avatarId: "", displayName: username })
                }
            }
        }
        xhr.send()
    }

    function selectUser(index, username) {
        root.selectedIndex = index
        root.selectedUsername = username
        root.errorText = ""
        profileFor(username, function (profile) {
            root.selectedProfile = profile
            picker.state = "credentials"
        })
    }

    function attemptLogin(secret) {
        sddm.login(root.selectedUsername, secret, sessionModel.lastIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.errorText = root.selectedProfile.role === "child"
                ? LocalizationManager.tr("login.wrongPin")
                : LocalizationManager.tr("login.wrongPassword")
            // pinStep (declared further down, in credentialsStep) is a
            // QML id — visible anywhere in this document regardless of
            // nesting, no parent-chain indirection needed.
            pinStep.entry = ""
        }
    }

    Rectangle { anchors.fill: parent; color: Theme.background }
    Image {
        anchors.fill: parent
        source: "file:///usr/share/kidsos/wallpapers/kidsos-default.svg"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.6
    }

    Item {
        id: picker
        anchors.fill: parent
        state: "picker"

        // ---- Step 1: "Who's using KIDS?" ----
        Column {
            id: pickerStep
            anchors.centerIn: parent
            spacing: Theme.spaceXxl
            opacity: 1

            KidsLogo { anchors.horizontalCenter: parent.horizontalCenter; variant: "welcome" }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("login.whoIsUsing")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH2
                color: Theme.textSecondary
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spaceLg

                Repeater {
                    model: userModel
                    delegate: Controls.AbstractButton {
                        id: card
                        focusPolicy: Qt.StrongFocus
                        implicitWidth: 220
                        implicitHeight: 240
                        onClicked: root.selectUser(index, model.name)

                        property var profile: ({ role: "child", avatarId: "" })
                        Component.onCompleted: root.profileFor(model.name, function (p) { card.profile = p })

                        background: KidsCard {
                            selected: root.selectedIndex === index
                            pressed: card.pressed
                            border.color: card.visualFocus ? Theme.primary : Theme.border
                        }
                        contentItem: Column {
                            anchors.centerIn: parent
                            spacing: Theme.spaceMd
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 88; height: 88
                                radius: 44
                                color: Qt.tint(card.profile.role === "parent" ? Theme.logo.s : Theme.logo.k, "#CCFFFFFF")
                                Text {
                                    anchors.centerIn: parent
                                    text: card.profile.role === "parent" ? "\u{1F464}" : "\u{1F916}"
                                    font.pixelSize: 40
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: model.realName.length > 0 ? model.realName : model.name
                                font.family: Theme.fontInterface
                                font.pixelSize: Theme.sizeH3
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                            }
                        }
                    }
                }
            }
        }

        // ---- Step 2: credential entry ----
        Column {
            id: credentialsStep
            anchors.centerIn: parent
            spacing: Theme.spaceXl
            opacity: 0
            visible: opacity > 0

            Controls.AbstractButton {
                anchors.left: parent.left
                implicitWidth: 44; implicitHeight: 44
                onClicked: { picker.state = "picker"; root.errorText = "" }
                background: Rectangle { radius: 22; color: Theme.surfaceAlt }
                contentItem: Text {
                    anchors.centerIn: parent
                    text: LocalizationManager.isRTL ? "→" : "←"
                    font.pixelSize: 18
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: LocalizationManager.tr("login.welcomeBack", [root.selectedProfile.displayName])
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH1
                font.weight: Font.DemiBold
                color: Theme.textPrimary
            }

            // Parent: real password field.
            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.selectedProfile.role === "parent"
                spacing: Theme.spaceMd
                width: 360

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: Theme.radiusLg
                    color: Theme.surface
                    border.width: passwordField.activeFocus ? 3 : 1
                    border.color: passwordField.activeFocus ? Theme.primary : Theme.border

                    Controls.TextField {
                        id: passwordField
                        anchors.fill: parent
                        anchors.margins: Theme.spaceMd
                        echoMode: TextInput.Password
                        font.family: Theme.fontInterface
                        font.pixelSize: Theme.sizeH3
                        background: Item {}
                        focus: picker.state === "credentials" && root.selectedProfile.role === "parent"
                        Keys.onReturnPressed: root.attemptLogin(text)
                    }
                }
                KidsButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: LocalizationManager.tr("common.continue")
                    onClicked: root.attemptLogin(passwordField.text)
                }
            }

            // Child: PIN pad, reusing the same components as onboarding.
            Column {
                id: pinStep
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.selectedProfile.role === "child"
                spacing: Theme.spaceXl

                property string entry: ""

                function digitPressed(d) {
                    if (entry.length >= 8)
                        return
                    entry += d
                    if (entry.length === 4)
                        submitTimer.start()
                }

                onVisibleChanged: if (!visible) entry = ""

                PinDots {
                    anchors.horizontalCenter: parent.horizontalCenter
                    length: 4
                    filledCount: Math.min(pinStep.entry.length, 4)
                }

                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 3
                    rowSpacing: Theme.spaceMd
                    columnSpacing: Theme.spaceMd

                    Repeater {
                        model: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
                        delegate: PinKey {
                            required property string modelData
                            label: modelData
                            onActivated: pinStep.digitPressed(modelData)
                        }
                    }
                    Item { width: 76; height: 76 }
                    PinKey { label: "0"; onActivated: pinStep.digitPressed("0") }
                    PinKey {
                        label: "⌫"; isAction: true
                        onActivated: pinStep.entry = pinStep.entry.slice(0, -1)
                    }
                }

                Timer {
                    id: submitTimer
                    interval: 200
                    onTriggered: root.attemptLogin(pinStep.entry)
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.errorText.length > 0
                text: root.errorText
                color: Theme.error
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeBody
            }
        }

        states: [
            State {
                name: "picker"
                PropertyChanges { target: pickerStep; opacity: 1 }
                PropertyChanges { target: credentialsStep; opacity: 0 }
            },
            State {
                name: "credentials"
                PropertyChanges { target: pickerStep; opacity: 0 }
                PropertyChanges { target: credentialsStep; opacity: 1 }
            }
        ]
        transitions: Transition {
            enabled: !Theme.reducedMotion
            NumberAnimation { property: "opacity"; duration: Theme.durationNormal; easing.type: Theme.easingStandard }
        }
    }
}

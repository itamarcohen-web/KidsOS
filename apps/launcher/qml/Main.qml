import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

Window {
    id: window
    visible: true
    visibility: Window.FullScreen
    color: Theme.background
    title: "KIDS"

    LayoutMirroring.enabled: LocalizationManager.isRTL
    LayoutMirroring.childrenInherit: true

    readonly property var profile: Bridge.profile
    readonly property string childName: profile && profile.name ? profile.name : ""
    property bool notificationsOpen: false
    property string searchQuery: ""

    Component.onCompleted: {
        if (profile && profile.language)
            LocalizationManager.setLanguage(profile.language)
    }

    readonly property var apps: [
        { id: "browser", cmd: "flatpak", args: ["run", "org.mozilla.firefox"], key: "browser", glyph: "\u{1F310}", color: Theme.logo.s },
        { id: "store", cmd: "", args: [], key: "store", glyph: "\u{1F6CD}", color: Theme.logo.k, placeholder: true },
        { id: "games", cmd: "", args: [], key: "games", glyph: "\u{1F3AE}", color: Theme.logo.i, placeholder: true },
        { id: "school", cmd: "", args: [], key: "school", glyph: "\u{1F393}", color: Theme.logo.d, placeholder: true },
        { id: "music", cmd: "elisa", args: [], key: "music", glyph: "\u{1F3B5}", color: "#A66BFF" },
        { id: "files", cmd: "dolphin", args: [], key: "files", glyph: "\u{1F4C1}", color: Theme.logo.s },
        { id: "calculator", cmd: "kcalc", args: [], key: "calculator", glyph: "\u{1F9EE}", color: Theme.logo.i },
        { id: "textEditor", cmd: "kate", args: [], key: "textEditor", glyph: "\u{1F4DD}", color: Theme.logo.d },
        { id: "screenshot", cmd: "spectacle", args: [], key: "screenshot", glyph: "\u{1F4F7}", color: Theme.logo.k },
        { id: "video", cmd: "haruna", args: [], key: "video", glyph: "\u{1F3AC}", color: "#FF7EB6" },
        { id: "photos", cmd: "gwenview", args: [], key: "photos", glyph: "\u{1F5BC}", color: Theme.logo.s },
        { id: "settings", cmd: "kidsos-settings", args: [], key: "settings", glyph: "⚙", color: Theme.logo.d },
        { id: "help", cmd: "", args: [], key: "help", glyph: "❓", color: Theme.logo.i, placeholder: true },
        { id: "updates", cmd: "", args: [], key: "updates", glyph: "\u{1F504}", color: Theme.logo.s, placeholder: true }
    ]

    readonly property var filteredApps: window.apps.filter(function (a) {
        if (window.searchQuery.length === 0)
            return true
        var label = LocalizationManager.tr("desktop.apps." + a.key)
        return label.toLowerCase().indexOf(window.searchQuery.toLowerCase()) !== -1
    })

    function launch(app) {
        if (app.placeholder) {
            comingSoon.open()
            return
        }
        Bridge.launchCommand(app.cmd, app.args)
    }

    Rectangle { anchors.fill: parent; color: Theme.background }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceXl
        spacing: Theme.spaceLg

        // ---- Top bar ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            KidsLogo { variant: "compact" }

            Item { Layout.fillWidth: true }

            Text {
                text: Qt.formatTime(clock.currentTime, "hh:mm")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeBody
                color: Theme.textSecondary
            }

            Text {
                text: "\u{1F4F6}"
                font.pixelSize: Theme.sizeBody
                color: Theme.textSecondary
                Controls.ToolTip.visible: wifiArea.containsMouse
                Controls.ToolTip.text: LocalizationManager.tr("desktop.wifi.connected")
                MouseArea { id: wifiArea; anchors.fill: parent; hoverEnabled: true }
            }

            Rectangle {
                width: 44; height: 44
                radius: 22
                color: window.notificationsOpen ? Theme.surfaceSunken : Theme.surfaceAlt
                Text { anchors.centerIn: parent; text: "\u{1F514}"; font.pixelSize: 18 }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.notificationsOpen = !window.notificationsOpen
                }
            }
        }

        Timer { id: clock; property date currentTime: new Date(); interval: 1000; running: true; repeat: true; onTriggered: currentTime = new Date() }

        // ---- Greeting ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            Rectangle {
                width: 64; height: 64
                radius: 32
                color: Qt.tint(Theme.logo.s, "#D9FFFFFF")
                Text {
                    anchors.centerIn: parent
                    text: window.profile && window.profile.avatarId ? "\u{1F60A}" : "\u{1F44B}"
                    font.pixelSize: 30
                }
            }

            Text {
                text: window.childName.length > 0
                      ? LocalizationManager.tr("desktop.greeting", [window.childName])
                      : LocalizationManager.tr("desktop.greetingEmpty")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH1
                font.weight: Font.DemiBold
                color: Theme.textPrimary
            }

            Item { Layout.fillWidth: true }
        }

        // ---- Search ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: Theme.radiusPill
            color: Theme.surface
            border.width: searchField.activeFocus ? 2 : 1
            border.color: searchField.activeFocus ? Theme.primary : Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceLg
                anchors.rightMargin: Theme.spaceLg
                spacing: Theme.spaceSm

                Text { text: "\u{1F50D}"; font.pixelSize: 16; color: Theme.textSecondary }

                Controls.TextField {
                    id: searchField
                    Layout.fillWidth: true
                    background: Item {}
                    font.family: Theme.fontInterface
                    font.pixelSize: Theme.sizeBody
                    color: Theme.textPrimary
                    placeholderText: LocalizationManager.tr("desktop.search.placeholder")
                    onTextChanged: window.searchQuery = text
                }
            }
        }

        // ---- App grid ----
        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 180
            cellHeight: 152
            model: window.filteredApps
            clip: true

            delegate: Item {
                width: grid.cellWidth
                height: grid.cellHeight
                required property var modelData

                AppTile {
                    anchors.centerIn: parent
                    label: LocalizationManager.tr("desktop.apps." + modelData.key)
                    glyph: modelData.glyph
                    tint: modelData.color
                    onActivated: window.launch(modelData)
                }
            }
        }
    }

    // ---- Bottom navigation ----
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Theme.spaceLg
        width: 320; height: 64
        radius: Theme.radiusPill
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        layer.enabled: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceXs

            Repeater {
                model: [
                    { key: "apps", glyph: "⬚" },
                    { key: "search", glyph: "\u{1F50D}" },
                    { key: "notifications", glyph: "\u{1F514}" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusPill
                    color: "transparent"

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { Layout.alignment: Qt.AlignHCenter; text: modelData.glyph; font.pixelSize: 16 }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: LocalizationManager.tr("desktop.nav." + modelData.key)
                            font.family: Theme.fontInterface
                            font.pixelSize: Theme.sizeCaption - 2
                            color: Theme.textSecondary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.key === "search")
                                searchField.forceActiveFocus()
                            else if (modelData.key === "notifications")
                                window.notificationsOpen = !window.notificationsOpen
                        }
                    }
                }
            }
        }
    }

    // ---- Notifications panel ----
    Rectangle {
        visible: window.notificationsOpen
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.spaceXl
        width: 320
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        height: 120

        Text {
            anchors.centerIn: parent
            text: LocalizationManager.tr("desktop.notifications.empty")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeBody
            color: Theme.textSecondary
        }
    }

    // ---- "Coming soon" placeholder dialog (Kids Store, Games, School, Help, Updates) ----
    Rectangle {
        id: comingSoon
        anchors.fill: parent
        color: Theme.overlay
        visible: opacity > 0
        opacity: 0

        function open() { opacity = 1 }
        function close() { opacity = 0 }

        Behavior on opacity { NumberAnimation { duration: Theme.durationNormal } }

        MouseArea { anchors.fill: parent; onClicked: comingSoon.close() }

        Rectangle {
            anchors.centerIn: parent
            width: 420
            radius: Theme.radiusLg
            color: Theme.surface
            height: content.implicitHeight + Theme.spaceXxl

            Column {
                id: content
                anchors.centerIn: parent
                width: parent.width - Theme.spaceXxl
                spacing: Theme.spaceMd

                Text {
                    width: parent.width
                    text: LocalizationManager.tr("desktop.store.comingSoonTitle")
                    font.family: Theme.fontInterface
                    font.pixelSize: Theme.sizeH3
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: LocalizationManager.tr("desktop.store.comingSoonBody")
                    font.family: Theme.fontInterface
                    font.pixelSize: Theme.sizeBody
                    color: Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                KidsButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: LocalizationManager.tr("common.continue")
                    onClicked: comingSoon.close()
                }
            }
        }
    }
}

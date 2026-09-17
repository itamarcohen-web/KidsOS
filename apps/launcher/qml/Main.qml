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
    property var recentIds: []

    Component.onCompleted: {
        if (profile && profile.language)
            LocalizationManager.setLanguage(profile.language)
        Theme.mode = Bridge.appearanceMode
    }

    // ---- App registry: single source of truth for the home row, the
    // launcher grid and system search. category ∈ launcher.category.*
    readonly property var apps: [
        { id: "browser", cmd: "flatpak", args: ["run", "org.mozilla.firefox"], key: "browser", glyph: "\u{1F310}", color: Theme.logo.s, category: "internet" },
        { id: "store", cmd: "", args: [], key: "store", glyph: "\u{1F6CD}", color: Theme.logo.k, category: "internet", placeholder: true },
        { id: "games", cmd: "", args: [], key: "games", glyph: "\u{1F3AE}", color: Theme.logo.i, category: "games", placeholder: true },
        { id: "school", cmd: "", args: [], key: "school", glyph: "\u{1F393}", color: Theme.logo.d, category: "school", placeholder: true },
        { id: "music", cmd: "elisa", args: [], key: "music", glyph: "\u{1F3B5}", color: "#A66BFF", category: "music" },
        { id: "files", cmd: "kidsos-files", args: [], key: "files", glyph: "\u{1F4C1}", category: "tools", color: Theme.logo.s },
        { id: "calculator", cmd: "kcalc", args: [], key: "calculator", glyph: "\u{1F9EE}", color: Theme.logo.i, category: "tools" },
        { id: "textEditor", cmd: "kate", args: [], key: "textEditor", glyph: "\u{1F4DD}", color: Theme.logo.d, category: "creativity" },
        { id: "screenshot", cmd: "spectacle", args: [], key: "screenshot", glyph: "\u{1F4F7}", color: Theme.logo.k, category: "tools" },
        { id: "video", cmd: "haruna", args: [], key: "video", glyph: "\u{1F3AC}", color: "#FF7EB6", category: "video" },
        { id: "photos", cmd: "gwenview", args: [], key: "photos", glyph: "\u{1F5BC}", color: Theme.logo.s, category: "creativity" },
        { id: "settings", cmd: "kidsos-settings", args: [], key: "settings", glyph: "⚙", color: Theme.logo.d, category: "tools" },
        { id: "help", cmd: "", args: [], key: "help", glyph: "❓", color: Theme.logo.i, category: "tools", placeholder: true },
        { id: "updates", cmd: "", args: [], key: "updates", glyph: "\u{1F504}", color: Theme.logo.s, category: "tools", placeholder: true }
    ]

    // Resolved-label copies for the launcher/search components, which
    // don't do their own localization lookups (keeps them reusable for
    // non-app result kinds too).
    readonly property var appsForUi: window.apps.map(function (a) {
        return { id: a.id, label: LocalizationManager.tr("desktop.apps." + a.key), glyph: a.glyph,
                 tint: a.color, category: a.category, kind: "app", placeholder: !!a.placeholder,
                 cmd: a.cmd, args: a.args }
    })

    readonly property var settingsForUi: [
        { id: "setting-internet", label: LocalizationManager.tr("settings.categories.internet"), glyph: "\u{1F4F6}", kind: "setting" },
        { id: "setting-sound", label: LocalizationManager.tr("settings.categories.sound"), glyph: "\u{1F50A}", kind: "setting" },
        { id: "setting-display", label: LocalizationManager.tr("settings.categories.display"), glyph: "\u{1F5A5}", kind: "setting" },
        { id: "setting-appearance", label: LocalizationManager.tr("settings.categories.appearance"), glyph: "\u{1F3A8}", kind: "setting" },
        { id: "setting-language", label: LocalizationManager.tr("settings.categories.language"), glyph: "\u{1F310}", kind: "setting" },
        { id: "setting-accessibility", label: LocalizationManager.tr("settings.categories.accessibility"), glyph: "♿", kind: "setting" }
    ]

    readonly property var pinnedApps: window.appsForUi.filter(function (a) {
        return ["browser", "store", "files", "settings"].indexOf(a.id) !== -1
    })

    readonly property var frequentlyUsed: window.appsForUi.filter(function (a) {
        return ["browser", "store", "games", "school", "music", "files"].indexOf(a.id) !== -1
    })

    // ---- Mock notifications (see docs/ROADMAP.md — no real parent
    // connectivity or update service behind these yet) ----
    property var notifications: [
        { id: "n1", group: "System", title: LocalizationManager.tr("notifications.mock.updateReady.title"), body: LocalizationManager.tr("notifications.mock.updateReady.body"), time: "09:14", read: false },
        { id: "n2", group: "System", title: LocalizationManager.tr("notifications.mock.downloadComplete.title"), body: LocalizationManager.tr("notifications.mock.downloadComplete.body"), time: "Yesterday", read: true },
        { id: "n3", group: "Family", title: LocalizationManager.tr("notifications.mock.parentApproved.title"), body: LocalizationManager.tr("notifications.mock.parentApproved.body"), time: "Yesterday", read: false }
    ]
    readonly property int unreadCount: notifications.filter(function (n) { return !n.read }).length

    function launch(app) {
        if (app.placeholder) {
            comingSoon.open()
            return
        }
        if (window.recentIds.indexOf(app.id) === -1)
            window.recentIds = [app.id].concat(window.recentIds).slice(0, 6)
        else
            window.recentIds = [app.id].concat(window.recentIds.filter(function (id) { return id !== app.id })).slice(0, 6)
        Bridge.launchCommand(app.cmd, app.args)
    }

    // Ticks once a minute so the greeting's time-of-day updates live
    // instead of freezing at whatever it was when the window opened.
    property date _now: new Date()
    Timer { interval: 60000; running: true; repeat: true; onTriggered: window._now = new Date() }

    readonly property string greeting: {
        var hour = window._now.getHours()
        var period = hour < 12 ? "morning" : (hour < 18 ? "afternoon" : "evening")
        return window.childName.length > 0
            ? LocalizationManager.tr("desktop.greeting." + period, [window.childName])
            : LocalizationManager.tr("desktop.greeting." + period + "Empty")
    }

    Rectangle { anchors.fill: parent; color: Theme.background }

    // Subtle decorative wallpaper blobs, matching branding/wallpapers/kidsos-default.svg
    Image {
        anchors.fill: parent
        source: "file:///usr/share/kidsos/wallpapers/kidsos-default.svg"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.6
        asynchronous: true
        cache: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceXl
        anchors.bottomMargin: 72 + Theme.spaceXl + Theme.spaceLg
        spacing: Theme.spaceXl

        // ---- Top bar: compact KIDS mark + status cluster ----
        RowLayout {
            Layout.fillWidth: true
            KidsLogo { variant: "compact" }
            Item { Layout.fillWidth: true }
            StatusCluster {
                wifiConnected: quickSettings.wifiEnabled
                bluetoothEnabled: quickSettings.bluetoothEnabled
                onActivated: quickSettings.open = !quickSettings.open
            }
        }

        // ---- Central branding moment: the large KIDS wordmark, once ----
        KidsLogo {
            Layout.alignment: Qt.AlignHCenter
            variant: "welcome"
        }

        // ---- Greeting ----
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: window.greeting
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH1
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }

        // ---- Frequently used ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spaceMd

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: LocalizationManager.tr("desktop.frequentlyUsed")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeH3
                font.weight: Font.DemiBold
                color: Theme.textSecondary
            }

            Flow {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(window.width - Theme.spaceXl * 2, 760)
                spacing: Theme.spaceLg

                Repeater {
                    model: window.frequentlyUsed
                    delegate: AppTile {
                        required property var modelData
                        label: modelData.label
                        glyph: modelData.glyph
                        tint: modelData.tint
                        onActivated: window.launch(modelData)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    // ---- Dock ----
    Dock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spaceLg
        pinnedApps: window.pinnedApps
        unreadNotifications: window.unreadCount
        onAppsRequested: launcherOverlay.open = true
        onSearchRequested: searchOverlay.open = true
        onNotificationsRequested: notificationCenter.open = true
        onQuickSettingsRequested: quickSettings.open = true
        onPinnedAppActivated: function (app) { window.launch(app) }
    }

    // ---- Overlays ----
    LauncherOverlay {
        id: launcherOverlay
        appsModel: window.appsForUi
        recentIds: window.recentIds
        onAppActivated: function (app) { launcherOverlay.open = false; window.launch(app) }
        onCloseRequested: launcherOverlay.open = false
    }

    SearchOverlay {
        id: searchOverlay
        appsModel: window.appsForUi
        settingsModel: window.settingsForUi
        onResultActivated: function (item) {
            searchOverlay.open = false
            if (item.kind === "app")
                window.launch(item)
            else if (item.kind === "setting")
                Bridge.launchCommand("kidsos-settings", [])
        }
        onCloseRequested: searchOverlay.open = false
    }

    NotificationCenter {
        id: notificationCenter
        notifications: window.notifications
        onDismissRequested: function (id) {
            window.notifications = window.notifications.filter(function (n) { return n.id !== id })
        }
        onClearAllRequested: window.notifications = []
        onCloseRequested: notificationCenter.open = false
    }

    QuickSettingsPanel {
        id: quickSettings
        onAppearanceChanged: function (mode) { Bridge.saveAppearanceMode(mode) }
        onCloseRequested: quickSettings.open = false
    }

    // ---- "Coming soon" placeholder dialog (Kids Store, Games, School, Help, KidsOS Updates) ----
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

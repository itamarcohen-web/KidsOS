import QtQuick
import KidsOS.Theme
import KidsOS.Localization

// Shared structural pattern for the settings categories that aren't
// functional yet (Internet, Sound, Bluetooth, Display, Keyboard, Mouse,
// Accounts, Storage, Apps, Accessibility) — establishes the visual
// pattern real functionality will slot into later without every category
// needing its own near-duplicate file. See docs/ROADMAP.md.
//
// Also shows the spec §28 "managed by parent" banner when a child is
// signed in and the Parent has locked this setting via kidsos-policy —
// queried for real (SettingsBridge::isSettingManaged), not decorative.
Item {
    id: root
    property string glyph: "⚙"
    property string title: ""
    property string settingId: ""

    readonly property bool managed: settingId.length > 0 && Bridge.isSettingManaged(settingId)

    Column {
        anchors.centerIn: parent
        spacing: Theme.spaceMd
        width: parent.width * 0.6

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 72; height: 72
            radius: Theme.radiusLg
            color: Theme.iconContainer
            Text { anchors.centerIn: parent; text: root.glyph; font.pixelSize: 32 }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.title
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH2
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }

        Rectangle {
            visible: root.managed
            anchors.horizontalCenter: parent.horizontalCenter
            width: managedRow.implicitWidth + Theme.spaceLg * 2
            height: 40
            radius: Theme.radiusPill
            color: Theme.surfaceAlt

            Row {
                id: managedRow
                anchors.centerIn: parent
                spacing: Theme.spaceSm
                Text { text: "\u{1F512}"; font.pixelSize: 14 }
                Text {
                    text: LocalizationManager.tr("settings.managedByParent")
                    font.family: Theme.fontInterface
                    font.pixelSize: Theme.sizeCaption
                    color: Theme.textSecondary
                }
            }
        }
    }
}

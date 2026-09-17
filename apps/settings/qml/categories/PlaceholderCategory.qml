import QtQuick
import KidsOS.Theme

// Shared structural pattern for the settings categories that aren't
// functional yet (Internet, Sound, Bluetooth, Display, Keyboard, Mouse,
// Accounts, Storage, Apps, Accessibility) — establishes the visual
// pattern real functionality will slot into later without every category
// needing its own near-duplicate file. See docs/ROADMAP.md.
Item {
    id: root
    property string glyph: "⚙"
    property string title: ""

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
    }
}

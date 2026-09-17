import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// Kids Files: a branded, simple front door onto the real filesystem.
// Large location cards open Dolphin at the right path — see
// docs/ARCHITECTURE.md for why this app doesn't reimplement a file
// manager from scratch.
Window {
    id: window
    visible: true
    width: 880
    height: 620
    minimumWidth: 640
    minimumHeight: 460
    color: Theme.background
    title: LocalizationManager.tr("files.title")

    LayoutMirroring.enabled: LocalizationManager.isRTL
    LayoutMirroring.childrenInherit: true

    readonly property var locations: [
        { id: "home", glyph: "\u{1F3E0}", tint: Theme.logo.s },
        { id: "school", glyph: "\u{1F393}", tint: Theme.logo.d },
        { id: "documents", glyph: "\u{1F4C4}", tint: Theme.logo.i },
        { id: "downloads", glyph: "⬇", tint: Theme.logo.k },
        { id: "pictures", glyph: "\u{1F5BC}", tint: Theme.logo.s },
        { id: "music", glyph: "\u{1F3B5}", tint: "#A66BFF" },
        { id: "videos", glyph: "\u{1F3AC}", tint: "#FF7EB6" },
        { id: "desktop", glyph: "\u{1F5A5}", tint: Theme.logo.d }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceXl
        spacing: Theme.spaceLg

        Text {
            text: LocalizationManager.tr("files.title")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH1
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: Math.max(2, Math.floor(window.width / 200))
            columnSpacing: Theme.spaceLg
            rowSpacing: Theme.spaceLg

            Repeater {
                model: window.locations
                delegate: AppTile {
                    required property var modelData
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 150
                    label: LocalizationManager.tr("files.locations." + modelData.id)
                    glyph: modelData.glyph
                    tint: modelData.tint
                    onActivated: Bridge.openLocation(modelData.id)
                }
            }
        }
    }
}

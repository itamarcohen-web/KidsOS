import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common
import "categories"

// KidsOS Settings: a sidebar of 13 plain-language categories (no Linux
// jargon — "Internet" not "NetworkManager configuration") and a content
// pane. Appearance and Language are fully functional; the rest establish
// the shared visual/structural pattern (PlaceholderCategory.qml) that
// real functionality slots into later — see docs/ROADMAP.md.
Window {
    id: window
    visible: true
    width: 980
    height: 660
    minimumWidth: 720
    minimumHeight: 480
    color: Theme.background
    title: LocalizationManager.tr("settings.title")

    LayoutMirroring.enabled: LocalizationManager.isRTL
    LayoutMirroring.childrenInherit: true

    Component.onCompleted: Theme.mode = Bridge.appearanceMode

    readonly property var categories: [
        { id: "appearance", glyph: "\u{1F3A8}" },
        { id: "internet", glyph: "\u{1F4F6}" },
        { id: "sound", glyph: "\u{1F50A}" },
        { id: "bluetooth", glyph: "\u{1F535}" },
        { id: "display", glyph: "\u{1F5A5}" },
        { id: "keyboard", glyph: "⌨" },
        { id: "mouse", glyph: "\u{1F5B1}" },
        { id: "language", glyph: "\u{1F310}" },
        { id: "accounts", glyph: "\u{1F464}" },
        { id: "storage", glyph: "\u{1F4BE}" },
        { id: "apps", glyph: "\u{1F4E6}" },
        { id: "accessibility", glyph: "♿" },
        { id: "about", glyph: "ℹ" }
    ].concat(Bridge.isChildAccount ? [] : [{ id: "localAiModels", glyph: "\u{1F6E1}" }])
    property string activeCategory: "appearance"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---- Sidebar ----
        Rectangle {
            Layout.preferredWidth: 240
            Layout.fillHeight: true
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spaceMd
                spacing: Theme.spaceXs

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: Theme.spaceMd
                    KidsLogo { variant: "compact" }
                }

                Repeater {
                    model: window.categories
                    delegate: Controls.AbstractButton {
                        id: navButton
                        required property var modelData
                        readonly property bool active: window.activeCategory === modelData.id
                        Layout.fillWidth: true
                        implicitHeight: 44
                        focusPolicy: Qt.StrongFocus
                        hoverEnabled: true
                        onClicked: window.activeCategory = modelData.id

                        background: Rectangle {
                            radius: Theme.radiusMd
                            color: navButton.active ? Theme.surfaceAlt : (navButton.hovered ? Theme.surfaceAlt : "transparent")
                            border.width: navButton.visualFocus ? 2 : 0
                            border.color: Theme.primary
                        }
                        contentItem: RowLayout {
                            anchors.leftMargin: Theme.spaceSm
                            anchors.rightMargin: Theme.spaceSm
                            spacing: Theme.spaceMd
                            Text { text: navButton.modelData.glyph; font.pixelSize: 16 }
                            Text {
                                Layout.fillWidth: true
                                text: LocalizationManager.tr("settings.categories." + navButton.modelData.id)
                                font.family: Theme.fontInterface
                                font.pixelSize: Theme.sizeBody
                                font.weight: navButton.active ? Font.DemiBold : Font.Normal
                                color: Theme.textPrimary
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ---- Content ----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                anchors.fill: parent
                anchors.margins: Theme.spaceXxl
                sourceComponent: {
                    if (window.activeCategory === "appearance") return appearanceComponent
                    if (window.activeCategory === "language") return languageComponent
                    if (window.activeCategory === "about") return aboutComponent
                    if (window.activeCategory === "accessibility") return accessibilityComponent
                    if (window.activeCategory === "localAiModels") return localAiModelsComponent
                    return placeholderComponent
                }
            }
        }
    }

    Component { id: appearanceComponent; AppearanceCategory {} }
    Component { id: languageComponent; LanguageCategory {} }
    Component { id: aboutComponent; AboutCategory {} }
    Component { id: accessibilityComponent; AccessibilityCategory {} }
    Component { id: localAiModelsComponent; LocalAiModelsCategory {} }
    Component {
        id: placeholderComponent
        PlaceholderCategory {
            readonly property var current: window.categories.find(function (c) { return c.id === window.activeCategory }) || {}
            glyph: current.glyph || "⚙"
            title: LocalizationManager.tr("settings.categories." + window.activeCategory)
            settingId: window.activeCategory
        }
    }
}

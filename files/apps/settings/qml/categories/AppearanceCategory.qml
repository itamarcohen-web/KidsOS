import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// Light / Dark / Match system. Fully functional: writes straight to
// Theme.mode (live preview) and persists via the SettingsBridge so the
// launcher picks up the same choice on next login.
Item {
    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.spaceXl

        Text {
            text: LocalizationManager.tr("settings.appearance.title")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH1
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }

        Row {
            spacing: Theme.spaceLg

            Repeater {
                model: ["light", "dark", "system"]
                delegate: Controls.AbstractButton {
                    id: card
                    required property string modelData
                    readonly property bool active: Theme.mode === modelData
                    focusPolicy: Qt.StrongFocus
                    implicitWidth: 180
                    implicitHeight: 140
                    onClicked: {
                        Theme.mode = card.modelData
                        Bridge.saveAppearanceMode(card.modelData)
                    }

                    background: KidsCard {
                        selected: card.active
                        pressed: card.pressed
                        border.color: card.visualFocus && !card.active ? Theme.primary : (card.active ? Theme.primary : Theme.border)
                    }

                    contentItem: Column {
                        spacing: Theme.spaceSm
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: card.modelData === "light" ? "☀" : (card.modelData === "dark" ? "\u{1F319}" : "\u{1F5A5}")
                            font.pixelSize: 32
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: LocalizationManager.tr("settings.appearance." + card.modelData)
                            font.family: Theme.fontInterface
                            font.pixelSize: Theme.sizeBody
                            font.weight: Font.Medium
                            color: Theme.textPrimary
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// Placeholder KidsOS Settings shell. Only the Language section is fully
// functional in this milestone; the rest establish the visual pattern
// future settings (Parent Controls, Screen Time, etc.) will slot into.
Window {
    id: window
    visible: true
    width: 900
    height: 640
    minimumWidth: 640
    minimumHeight: 480
    color: Theme.background
    title: LocalizationManager.tr("settings.title")

    LayoutMirroring.enabled: LocalizationManager.isRTL
    LayoutMirroring.childrenInherit: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceXl
        spacing: Theme.spaceLg

        Text {
            text: LocalizationManager.tr("settings.title")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH1
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }

        // ---- Language (functional) ----
        KidsCard {
            Layout.fillWidth: true
            Layout.preferredHeight: languageColumn.implicitHeight + Theme.spaceXl

            Column {
                id: languageColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spaceLg
                spacing: Theme.spaceMd

                Text {
                    text: LocalizationManager.tr("settings.sections.language")
                    font.family: Theme.fontInterface
                    font.pixelSize: Theme.sizeH3
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }

                Row {
                    spacing: Theme.spaceMd
                    Repeater {
                        model: LocalizationManager.supportedLanguages
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: LocalizationManager.language === modelData.code
                            width: 120; height: 48
                            radius: Theme.radiusPill
                            color: active ? Theme.primary : Theme.surfaceAlt
                            border.width: active ? 0 : 1
                            border.color: Theme.border

                            Text {
                                anchors.centerIn: parent
                                text: modelData.nativeName
                                font.family: Theme.fontInterface
                                font.pixelSize: Theme.sizeBody
                                color: active ? Theme.textOnPrimary : Theme.textPrimary
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: LocalizationManager.setLanguage(modelData.code)
                            }
                        }
                    }
                }
            }
        }

        // ---- Placeholder sections ----
        Repeater {
            model: ["profile", "display", "sound", "about"]
            delegate: KidsCard {
                required property string modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                interactive: false

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spaceLg

                    Text {
                        text: LocalizationManager.tr("settings.sections." + modelData)
                        font.family: Theme.fontInterface
                        font.pixelSize: Theme.sizeBodyLarge
                        color: Theme.textPrimary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "›"
                        font.pixelSize: Theme.sizeH3
                        color: Theme.textSecondary
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

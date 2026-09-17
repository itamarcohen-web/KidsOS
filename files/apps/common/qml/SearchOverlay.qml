import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization

// System-wide KidsOS search: apps, Settings sections, and (mock) files.
// A fast, centered command-palette style overlay.
Item {
    id: root

    property bool open: false
    property var appsModel: []     // [{id,label,glyph,tint,kind:"app"}]
    property var settingsModel: [] // [{id,label,glyph,kind:"setting"}]
    property var filesModel: []    // [{id,label,glyph,kind:"file"}]
    property string query: ""

    signal resultActivated(var item)
    signal closeRequested()

    anchors.fill: parent
    visible: opacity > 0
    opacity: open ? 1 : 0
    scale: open ? 1 : 0.97
    Behavior on opacity { enabled: !Theme.reducedMotion; NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easingStandard } }
    Behavior on scale { enabled: !Theme.reducedMotion; NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easingStandard } }

    onOpenChanged: if (open) { query = ""; field.forceActiveFocus() }

    function _matches(item) {
        return root.query.length === 0 || item.label.toLowerCase().indexOf(root.query.toLowerCase()) !== -1
    }

    readonly property var results: root.query.length === 0 ? [] :
        root.appsModel.filter(_matches).concat(root.settingsModel.filter(_matches)).concat(root.filesModel.filter(_matches))

    Rectangle { anchors.fill: parent; color: Theme.overlay }
    MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }

    Rectangle {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.15
        width: Math.min(parent.width - Theme.spaceXxl * 2, 640)
        height: Math.min(560, field.height + Theme.spaceXl * 2 + resultsList.contentHeight + Theme.spaceMd)
        radius: Theme.radiusLg
        color: Theme.background
        border.width: 1
        border.color: Theme.border

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceMd

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                radius: Theme.radiusPill
                color: Theme.surface
                border.width: field.activeFocus ? 2 : 1
                border.color: field.activeFocus ? Theme.primary : Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spaceLg
                    anchors.rightMargin: Theme.spaceLg
                    Text { text: "\u{1F50D}"; font.pixelSize: 16; color: Theme.textSecondary }
                    Controls.TextField {
                        id: field
                        Layout.fillWidth: true
                        background: Item {}
                        font.family: Theme.fontInterface
                        font.pixelSize: Theme.sizeBody
                        color: Theme.textPrimary
                        placeholderText: LocalizationManager.tr("search.placeholder")
                        onTextChanged: root.query = text
                        Keys.onEscapePressed: root.closeRequested()
                        Keys.onReturnPressed: if (root.results.length > 0) root.resultActivated(root.results[0])
                    }
                }
            }

            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.results
                spacing: Theme.spaceXs

                delegate: Controls.AbstractButton {
                    id: resultButton
                    required property var modelData
                    width: resultsList.width
                    implicitHeight: 56
                    focusPolicy: Qt.StrongFocus
                    hoverEnabled: true
                    onClicked: root.resultActivated(modelData)

                    background: Rectangle {
                        radius: Theme.radiusMd
                        color: resultButton.hovered || resultButton.visualFocus ? Theme.surfaceAlt : "transparent"
                    }
                    contentItem: RowLayout {
                        anchors.leftMargin: Theme.spaceMd
                        anchors.rightMargin: Theme.spaceMd
                        spacing: Theme.spaceMd
                        Text { text: resultButton.modelData.glyph; font.pixelSize: 20 }
                        Text {
                            Layout.fillWidth: true
                            text: resultButton.modelData.label
                            font.family: Theme.fontInterface
                            font.pixelSize: Theme.sizeBody
                            color: Theme.textPrimary
                        }
                        Text {
                            text: LocalizationManager.tr("search.kind." + resultButton.modelData.kind)
                            font.family: Theme.fontInterface
                            font.pixelSize: Theme.sizeCaption
                            color: Theme.textSecondary
                        }
                    }
                }
            }

            Text {
                visible: root.query.length > 0 && root.results.length === 0
                Layout.alignment: Qt.AlignHCenter
                text: LocalizationManager.tr("search.noResults")
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeBody
                color: Theme.textSecondary
            }
        }
    }
}

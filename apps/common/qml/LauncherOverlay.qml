import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization

// Full-screen app launcher: search, recently-used row, category tabs,
// and a large card grid. Opens/closes with a fast fade+scale (respects
// reduced motion via Theme.reducedMotion).
Item {
    id: root

    property bool open: false
    property var appsModel: [] // [{id,label,glyph,tint,category,placeholder}]
    property var recentIds: []

    signal appActivated(var app)
    signal closeRequested()

    readonly property var categories: ["all", "games", "school", "creativity", "internet", "music", "video", "tools"]
    property string activeCategory: "all"
    property string query: ""

    anchors.fill: parent
    visible: opacity > 0
    opacity: open ? 1 : 0
    scale: open ? 1 : 0.97

    Behavior on opacity { enabled: !Theme.reducedMotion; NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easingStandard } }
    Behavior on scale { enabled: !Theme.reducedMotion; NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easingStandard } }

    onOpenChanged: if (open) { query = ""; activeCategory = "all"; searchField.forceActiveFocus() }

    readonly property var recentApps: root.appsModel.filter(function (a) {
        return root.recentIds.indexOf(a.id) !== -1
    })

    readonly property var filteredApps: root.appsModel.filter(function (a) {
        if (root.activeCategory !== "all" && a.category !== root.activeCategory)
            return false
        if (root.query.length > 0 && a.label.toLowerCase().indexOf(root.query.toLowerCase()) === -1)
            return false
        return true
    })

    Rectangle { anchors.fill: parent; color: Theme.overlay }

    MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.spaceXxl * 2, 1100)
        height: Math.min(parent.height - Theme.spaceXxl * 2, 760)
        radius: Theme.radiusLg
        color: Theme.background
        border.width: 1
        border.color: Theme.border

        MouseArea { anchors.fill: parent } // swallow clicks so they don't close the overlay

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceXl
            spacing: Theme.spaceLg

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: LocalizationManager.tr("launcher.title")
                    font.family: Theme.fontInterface
                    font.pixelSize: Theme.sizeH1
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }
                Item { Layout.fillWidth: true }
                Controls.AbstractButton {
                    implicitWidth: 40; implicitHeight: 40
                    onClicked: root.closeRequested()
                    background: Rectangle { radius: 20; color: Theme.surfaceAlt }
                    contentItem: Text { text: "✕"; anchors.centerIn: parent; font.pixelSize: 16; color: Theme.textPrimary }
                }
            }

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
                    Text { text: "\u{1F50D}"; font.pixelSize: 16; color: Theme.textSecondary }
                    Controls.TextField {
                        id: searchField
                        Layout.fillWidth: true
                        background: Item {}
                        font.family: Theme.fontInterface
                        font.pixelSize: Theme.sizeBody
                        color: Theme.textPrimary
                        placeholderText: LocalizationManager.tr("launcher.searchPlaceholder")
                        onTextChanged: root.query = text
                        Keys.onEscapePressed: root.closeRequested()
                    }
                }
            }

            Row {
                Layout.fillWidth: true
                spacing: Theme.spaceSm
                Repeater {
                    model: root.categories
                    delegate: Controls.AbstractButton {
                        id: catButton
                        required property string modelData
                        readonly property bool active: root.activeCategory === modelData
                        focusPolicy: Qt.StrongFocus
                        onClicked: root.activeCategory = modelData

                        implicitWidth: catLabel.implicitWidth + Theme.spaceLg * 2
                        implicitHeight: 40
                        background: Rectangle {
                            radius: Theme.radiusPill
                            color: catButton.active ? Theme.primary : Theme.surfaceAlt
                        }
                        contentItem: Text {
                            id: catLabel
                            anchors.centerIn: parent
                            text: LocalizationManager.tr("launcher.category." + catButton.modelData)
                            font.family: Theme.fontInterface
                            font.pixelSize: Theme.sizeCaption
                            font.weight: Font.Medium
                            color: catButton.active ? Theme.textOnPrimary : Theme.textPrimary
                        }
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: resultsColumn.implicitHeight
                clip: true

                Column {
                    id: resultsColumn
                    width: parent.width
                    spacing: Theme.spaceLg

                    Column {
                        visible: root.activeCategory === "all" && root.query.length === 0 && root.recentApps.length > 0
                        width: parent.width
                        spacing: Theme.spaceSm

                        Text {
                            text: LocalizationManager.tr("launcher.recentlyUsed")
                            font.family: Theme.fontInterface
                            font.pixelSize: Theme.sizeH3
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }
                        Flow {
                            width: parent.width
                            spacing: Theme.spaceMd
                            Repeater {
                                model: root.recentApps
                                delegate: AppTile {
                                    required property var modelData
                                    label: modelData.label
                                    glyph: modelData.glyph
                                    tint: modelData.tint
                                    onActivated: root.appActivated(modelData)
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spaceSm

                        Text {
                            text: LocalizationManager.tr("launcher.allApps")
                            font.family: Theme.fontInterface
                            font.pixelSize: Theme.sizeH3
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }
                        Flow {
                            width: parent.width
                            spacing: Theme.spaceMd
                            Repeater {
                                model: root.filteredApps
                                delegate: AppTile {
                                    required property var modelData
                                    label: modelData.label
                                    glyph: modelData.glyph
                                    tint: modelData.tint
                                    onActivated: root.appActivated(modelData)
                                }
                            }
                        }
                        Text {
                            visible: root.filteredApps.length === 0
                            text: LocalizationManager.tr("search.noResults")
                            font.family: Theme.fontInterface
                            font.pixelSize: Theme.sizeBody
                            color: Theme.textSecondary
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization

// Bottom dock / navigation: Apps, Search, pinned apps, Notifications,
// status cluster (Wi-Fi/Bluetooth/volume/clock). Rounded, translucent,
// with clear hover/focus states and a slide animation when shown/hidden.
Item {
    id: root

    property var pinnedApps: [] // [{id, label, glyph, tint}]
    property int unreadNotifications: 0
    property bool revealed: true

    signal appsRequested()
    signal searchRequested()
    signal notificationsRequested()
    signal quickSettingsRequested()
    signal pinnedAppActivated(var app)

    implicitHeight: 72
    implicitWidth: content.implicitWidth + Theme.spaceLg * 2

    y: revealed ? 0 : height + Theme.spaceXxl
    Behavior on y {
        NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easingStandard }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusPill
        color: Theme.isDark ? "#CC1E212E" : "#F2FFFFFF"
        border.width: 1
        border.color: Theme.border
    }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Theme.spaceMd

        DockButton {
            iconGlyph: "⬚"
            labelText: LocalizationManager.tr("desktop.nav.apps")
            onActivated: root.appsRequested()
        }
        DockButton {
            iconGlyph: "\u{1F50D}"
            labelText: LocalizationManager.tr("desktop.nav.search")
            onActivated: root.searchRequested()
        }

        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.margins: Theme.spaceSm; color: Theme.border }

        Row {
            spacing: Theme.spaceXs
            Repeater {
                model: root.pinnedApps
                delegate: Controls.AbstractButton {
                    id: pinnedButton
                    required property var modelData
                    focusPolicy: Qt.StrongFocus
                    hoverEnabled: true
                    onClicked: root.pinnedAppActivated(modelData)

                    implicitWidth: 44; implicitHeight: 44
                    background: Rectangle {
                        radius: Theme.radiusMd
                        color: pinnedButton.hovered || pinnedButton.visualFocus ? Theme.surfaceAlt : "transparent"
                        border.width: pinnedButton.visualFocus ? 2 : 0
                        border.color: Theme.primary
                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    }
                    contentItem: Text {
                        text: pinnedButton.modelData.glyph
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        Rectangle {
            visible: root.pinnedApps.length > 0
            Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.margins: Theme.spaceSm; color: Theme.border
        }

        // Notifications bell with unread badge
        Controls.AbstractButton {
            id: bellButton
            focusPolicy: Qt.StrongFocus
            hoverEnabled: true
            onClicked: root.notificationsRequested()
            implicitWidth: 44; implicitHeight: 44

            background: Rectangle {
                radius: Theme.radiusMd
                color: bellButton.hovered || bellButton.visualFocus ? Theme.surfaceAlt : "transparent"
                border.width: bellButton.visualFocus ? 2 : 0
                border.color: Theme.primary
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }
            }
            contentItem: Item {
                Text { anchors.centerIn: parent; text: "\u{1F514}"; font.pixelSize: 20 }
                Rectangle {
                    visible: root.unreadNotifications > 0
                    width: 16; height: 16
                    radius: 8
                    color: Theme.secondary
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 2
                    anchors.rightMargin: 2
                    Text {
                        anchors.centerIn: parent
                        text: root.unreadNotifications > 9 ? "9+" : root.unreadNotifications
                        color: "white"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }
            }
        }

        StatusCluster {
            onActivated: root.quickSettingsRequested()
        }
    }

    component DockButton: Controls.AbstractButton {
        id: dockBtn
        property string iconGlyph: ""
        property string labelText: ""
        focusPolicy: Qt.StrongFocus
        hoverEnabled: true
        signal activated()
        onClicked: dockBtn.activated()

        implicitWidth: dockContent.implicitWidth + Theme.spaceMd * 2
        implicitHeight: 48

        background: Rectangle {
            radius: Theme.radiusPill
            color: dockBtn.hovered || dockBtn.visualFocus ? Theme.surfaceAlt : "transparent"
            border.width: dockBtn.visualFocus ? 2 : 0
            border.color: Theme.primary
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
        }
        contentItem: Row {
            id: dockContent
            spacing: Theme.spaceXs
            Text { text: dockBtn.iconGlyph; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: dockBtn.labelText
                font.family: Theme.fontInterface
                font.pixelSize: Theme.sizeCaption
                font.weight: Font.Medium
                color: Theme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}

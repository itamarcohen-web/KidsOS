import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization

// Slide-in notification panel. Anchors to the trailing edge (right in
// LTR, left in RTL — handled automatically by the parent Window's
// LayoutMirroring, not special-cased here). Supports grouping, dismiss,
// clear all, and an unread state per notification.
Item {
    id: root

    property bool open: false
    property var notifications: [] // [{id, group, title, body, time, read}]

    signal dismissRequested(string id)
    signal clearAllRequested()
    signal closeRequested()

    anchors.fill: parent
    visible: opacity > 0 || open
    opacity: open ? 1 : 0
    Behavior on opacity { enabled: !Theme.reducedMotion; NumberAnimation { duration: Theme.durationFast } }

    MouseArea { anchors.fill: parent; enabled: root.open; onClicked: root.closeRequested() }

    readonly property var groupedKeys: {
        var seen = []
        for (var i = 0; i < root.notifications.length; i++) {
            var g = root.notifications[i].group
            if (seen.indexOf(g) === -1) seen.push(g)
        }
        return seen
    }

    Rectangle {
        id: panel
        width: 380
        height: parent.height
        anchors.top: parent.top
        anchors.right: parent.right
        x: root.open ? 0 : width
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        Behavior on x { enabled: !Theme.reducedMotion; NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easingStandard } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceMd

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: LocalizationManager.tr("notifications.title")
                    font.family: Theme.fontInterface
                    font.pixelSize: Theme.sizeH2
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }
                Item { Layout.fillWidth: true }
                Controls.AbstractButton {
                    visible: root.notifications.length > 0
                    implicitHeight: 32
                    implicitWidth: clearLabel.implicitWidth + Theme.spaceMd * 2
                    onClicked: root.clearAllRequested()
                    background: Rectangle { radius: Theme.radiusPill; color: Theme.surfaceAlt }
                    contentItem: Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: LocalizationManager.tr("notifications.clearAll")
                        font.family: Theme.fontInterface
                        font.pixelSize: Theme.sizeCaption
                        color: Theme.textPrimary
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: list.implicitHeight

                Column {
                    id: list
                    width: parent.width
                    spacing: Theme.spaceLg

                    Repeater {
                        model: root.groupedKeys
                        delegate: Column {
                            required property string modelData
                            width: list.width
                            spacing: Theme.spaceSm

                            Text {
                                text: modelData
                                font.family: Theme.fontInterface
                                font.pixelSize: Theme.sizeCaption
                                font.weight: Font.DemiBold
                                color: Theme.textSecondary
                            }

                            Repeater {
                                model: root.notifications.filter(function (n) { return n.group === modelData })
                                delegate: Rectangle {
                                    required property var modelData
                                    width: list.width
                                    height: notifCol.implicitHeight + Theme.spaceMd * 2
                                    radius: Theme.radiusMd
                                    color: Theme.surfaceAlt

                                    Rectangle {
                                        visible: !modelData.read
                                        width: 8; height: 8; radius: 4
                                        color: Theme.primary
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: Theme.spaceSm
                                    }

                                    Column {
                                        id: notifCol
                                        anchors.left: parent.left
                                        anchors.right: closeBtn.left
                                        anchors.top: parent.top
                                        anchors.margins: Theme.spaceMd
                                        spacing: 4

                                        Text {
                                            width: parent.width
                                            text: modelData.title
                                            font.family: Theme.fontInterface
                                            font.pixelSize: Theme.sizeBody
                                            font.weight: Font.Medium
                                            color: Theme.textPrimary
                                            wrapMode: Text.WordWrap
                                        }
                                        Text {
                                            width: parent.width
                                            text: modelData.body
                                            font.family: Theme.fontInterface
                                            font.pixelSize: Theme.sizeCaption
                                            color: Theme.textSecondary
                                            wrapMode: Text.WordWrap
                                        }
                                        Text {
                                            text: modelData.time
                                            font.family: Theme.fontInterface
                                            font.pixelSize: Theme.sizeCaption - 2
                                            color: Theme.textSecondary
                                            opacity: 0.7
                                        }
                                    }

                                    Controls.AbstractButton {
                                        id: closeBtn
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: Theme.spaceSm
                                        implicitWidth: 24; implicitHeight: 24
                                        onClicked: root.dismissRequested(modelData.id)
                                        background: Item {}
                                        contentItem: Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            font.pixelSize: 12
                                            color: Theme.textSecondary
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.notifications.length === 0
                        width: list.width
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: Theme.spaceXxl
                        text: LocalizationManager.tr("desktop.notifications.empty")
                        font.family: Theme.fontInterface
                        font.pixelSize: Theme.sizeBody
                        color: Theme.textSecondary
                    }
                }
            }
        }
    }
}

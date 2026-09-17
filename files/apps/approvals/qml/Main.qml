import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// Parent Approval app (spec §16, §26). Approve/Deny/Revoke trigger a
// polkit auth_admin check inside kidsos-installer — the OS's own
// polkit agent prompts for the Parent password on every single action,
// every time (never cached). This window shows no password field of
// its own; that prompt is real OS UI, not KidsOS UI.
Window {
    id: window
    visible: true
    width: 760
    height: 640
    minimumWidth: 560
    minimumHeight: 420
    color: Theme.background
    title: LocalizationManager.tr("approvals.title")

    LayoutMirroring.enabled: LocalizationManager.isRTL
    LayoutMirroring.childrenInherit: true

    property string activeTab: "pending"
    property var pending: Bridge.pendingRequests()
    property var trusted: Bridge.trustedApps()

    function refresh() {
        window.pending = Bridge.pendingRequests()
        window.trusted = Bridge.trustedApps()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceXl
        spacing: Theme.spaceLg

        Text {
            text: LocalizationManager.tr("approvals.title")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH1
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }

        Row {
            spacing: Theme.spaceSm
            Repeater {
                model: ["pending", "trusted"]
                delegate: Controls.AbstractButton {
                    id: tabButton
                    required property string modelData
                    readonly property bool active: window.activeTab === modelData
                    onClicked: window.activeTab = modelData
                    implicitWidth: tabLabel.implicitWidth + Theme.spaceLg * 2
                    implicitHeight: 40
                    background: Rectangle { radius: Theme.radiusPill; color: tabButton.active ? Theme.primary : Theme.surfaceAlt }
                    contentItem: Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: LocalizationManager.tr("approvals.tab." + tabButton.modelData)
                        font.family: Theme.fontInterface
                        font.pixelSize: Theme.sizeCaption
                        font.weight: Font.Medium
                        color: tabButton.active ? Theme.textOnPrimary : Theme.textPrimary
                    }
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
                spacing: Theme.spaceMd

                // ---- Pending requests ----
                Repeater {
                    model: window.activeTab === "pending" ? window.pending : []
                    delegate: KidsCard {
                        id: card
                        required property var modelData
                        width: list.width
                        height: cardContent.implicitHeight + Theme.spaceXl
                        interactive: false

                        RowLayout {
                            id: cardContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spaceLg
                            spacing: Theme.spaceLg

                            Rectangle {
                                Layout.preferredWidth: 56; Layout.preferredHeight: 56
                                radius: Theme.radiusMd
                                color: Theme.iconContainer
                                Text {
                                    anchors.centerIn: parent
                                    text: card.modelData.kind === "external" ? "\u{1F4E6}" : "\u{1F3AE}"
                                    font.pixelSize: 26
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: card.modelData.kind === "external"
                                          ? card.modelData.file_path.split("/").pop()
                                          : card.modelData.app_name
                                    font.family: Theme.fontInterface
                                    font.pixelSize: Theme.sizeH3
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                }
                                Text {
                                    text: LocalizationManager.tr("approvals.requestedBy", [Bridge.childDisplayName(card.modelData.child_id)])
                                    font.family: Theme.fontInterface
                                    font.pixelSize: Theme.sizeCaption
                                    color: Theme.textSecondary
                                }
                                Text {
                                    text: card.modelData.kind === "external"
                                          ? LocalizationManager.tr("approvals.externalSource") + " · " + card.modelData.file_type
                                          : LocalizationManager.tr("approvals.storeSource") + (card.modelData.permissions ? " · " + card.modelData.permissions : "")
                                    font.family: Theme.fontInterface
                                    font.pixelSize: Theme.sizeCaption
                                    color: Theme.textSecondary
                                }
                            }

                            KidsButton {
                                text: LocalizationManager.tr("approvals.approve")
                                variant: "primary"
                                onClicked: { Bridge.approve(card.modelData.id); window.refresh() }
                            }
                            KidsButton {
                                text: LocalizationManager.tr("approvals.deny")
                                variant: "secondary"
                                onClicked: { Bridge.deny(card.modelData.id); window.refresh() }
                            }
                        }
                    }
                }

                Text {
                    visible: window.activeTab === "pending" && window.pending.length === 0
                    width: list.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Theme.spaceXxl
                    text: LocalizationManager.tr("approvals.noPending")
                    font.family: Theme.fontInterface
                    font.pixelSize: Theme.sizeBody
                    color: Theme.textSecondary
                }

                // ---- Trusted apps ----
                Repeater {
                    model: window.activeTab === "trusted" ? window.trusted : []
                    delegate: KidsCard {
                        id: trustCard
                        required property var modelData
                        width: list.width
                        height: 72
                        interactive: false

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spaceLg
                            Text {
                                Layout.fillWidth: true
                                text: trustCard.modelData.path.split("/").pop()
                                font.family: Theme.fontInterface
                                font.pixelSize: Theme.sizeBody
                                color: Theme.textPrimary
                                elide: Text.ElideMiddle
                            }
                            Text {
                                text: LocalizationManager.tr("approvals.approved")
                                color: Theme.success
                                font.family: Theme.fontInterface
                                font.pixelSize: Theme.sizeCaption
                            }
                            KidsButton {
                                text: LocalizationManager.tr("approvals.revoke")
                                variant: "secondary"
                                onClicked: { Bridge.revoke(trustCard.modelData.request_id); window.refresh() }
                            }
                        }
                    }
                }

                Text {
                    visible: window.activeTab === "trusted" && window.trusted.length === 0
                    width: list.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Theme.spaceXxl
                    text: LocalizationManager.tr("approvals.noTrusted")
                    font.family: Theme.fontInterface
                    font.pixelSize: Theme.sizeBody
                    color: Theme.textSecondary
                }
            }
        }
    }
}

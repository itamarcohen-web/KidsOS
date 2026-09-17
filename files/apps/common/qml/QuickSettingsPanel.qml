import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization

// Quick Settings: large, simple toggles anchored near the status cluster.
// Dark Mode is fully functional (drives Theme.mode); Wi-Fi/Bluetooth/
// Night Light are local UI state for this milestone — see docs/ROADMAP.md
// for wiring them to real NetworkManager/BlueZ/night-color backends.
// Rows use the shared ToggleRow.qml component (also used by
// apps/settings' Accessibility category) so every switch in KidsOS looks
// and behaves identically.
Item {
    id: root

    property bool open: false
    property bool wifiEnabled: true
    property bool bluetoothEnabled: false
    property bool nightLightEnabled: false
    property int volume: 70

    signal appearanceChanged(string mode)
    signal closeRequested()

    anchors.fill: parent
    visible: opacity > 0
    opacity: open ? 1 : 0
    Behavior on opacity { enabled: !Theme.reducedMotion; NumberAnimation { duration: Theme.durationFast } }

    MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }

    Rectangle {
        id: panel
        width: 320
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.spaceLg
        height: content.implicitHeight + Theme.spaceLg * 2
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        scale: root.open ? 1 : 0.95
        y: root.open ? Theme.spaceLg : 0
        Behavior on scale { enabled: !Theme.reducedMotion; NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingStandard } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceSm

            ToggleRow {
                Layout.fillWidth: true
                icon: "\u{1F4F6}"
                label: LocalizationManager.tr("quickSettings.wifi")
                checked: root.wifiEnabled
                onToggled: root.wifiEnabled = !root.wifiEnabled
            }
            ToggleRow {
                Layout.fillWidth: true
                icon: "\u{1F535}"
                label: LocalizationManager.tr("quickSettings.bluetooth")
                checked: root.bluetoothEnabled
                onToggled: root.bluetoothEnabled = !root.bluetoothEnabled
            }
            ToggleRow {
                Layout.fillWidth: true
                icon: Theme.isDark ? "\u{1F319}" : "☀"
                label: LocalizationManager.tr("quickSettings.darkMode")
                checked: Theme.isDark
                onToggled: {
                    Theme.mode = Theme.isDark ? "light" : "dark"
                    root.appearanceChanged(Theme.mode)
                }
            }
            ToggleRow {
                Layout.fillWidth: true
                icon: "\u{1F307}"
                label: LocalizationManager.tr("quickSettings.nightLight")
                checked: root.nightLightEnabled
                onToggled: root.nightLightEnabled = !root.nightLightEnabled
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spaceSm
                spacing: Theme.spaceXs

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "\u{1F50A}"; font.pixelSize: 16 }
                    Text {
                        text: LocalizationManager.tr("quickSettings.volume")
                        font.family: Theme.fontInterface
                        font.pixelSize: Theme.sizeBody
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.volume + "%"
                        font.family: Theme.fontInterface
                        font.pixelSize: Theme.sizeCaption
                        color: Theme.textSecondary
                    }
                }
                Controls.Slider {
                    Layout.fillWidth: true
                    from: 0; to: 100
                    value: root.volume
                    onMoved: root.volume = Math.round(value)
                }
            }
        }
    }
}

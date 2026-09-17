import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization

// Large, simple icon + label + switch row — shared by QuickSettingsPanel
// and Settings category panels so every toggle in KidsOS looks and
// behaves identically.
Controls.AbstractButton {
    id: root
    property string icon: ""
    property string label: ""
    property bool checked: false
    signal toggled()
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    onClicked: root.toggled()

    implicitHeight: 52
    background: Rectangle {
        radius: Theme.radiusMd
        color: root.hovered || root.visualFocus ? Theme.surfaceAlt : "transparent"
        border.width: root.visualFocus ? 2 : 0
        border.color: Theme.primary
    }
    contentItem: RowLayout {
        anchors.leftMargin: Theme.spaceSm
        anchors.rightMargin: Theme.spaceSm
        spacing: Theme.spaceMd
        Text { text: root.icon; font.pixelSize: 18 }
        Text {
            text: root.label
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeBody
            color: Theme.textPrimary
            Layout.fillWidth: true
        }
        Rectangle {
            width: 44; height: 26
            radius: 13
            color: root.checked ? Theme.primary : Theme.border
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
            Rectangle {
                // Explicit RTL check: this is a raw x-position, not an
                // anchor, so Qt's LayoutMirroring won't flip it for us.
                width: 20; height: 20
                radius: 10
                color: "white"
                y: 3
                x: (root.checked !== LocalizationManager.isRTL) ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingStandard } }
            }
        }
    }
}

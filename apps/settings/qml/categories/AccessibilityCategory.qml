import QtQuick
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization
import KidsOS.Common

// Fully functional: Reduce Motion drives Theme.reducedMotion, which every
// overlay/transition in the shared component library already checks
// (LauncherOverlay, SearchOverlay, NotificationCenter, QuickSettingsPanel,
// Dock, OnboardingPage). Large-cursor/high-contrast are placeholders for
// now — see docs/ROADMAP.md.
Item {
    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.spaceLg

        Text {
            text: LocalizationManager.tr("settings.categories.accessibility")
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeH1
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }

        ToggleRow {
            width: 420
            icon: "\u{1F3C3}"
            label: LocalizationManager.tr("settings.accessibility.reduceMotion")
            checked: Theme.reducedMotion
            onToggled: Theme.reducedMotion = !Theme.reducedMotion
        }
    }
}

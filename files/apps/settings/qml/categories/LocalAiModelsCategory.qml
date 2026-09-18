import QtQuick
import QtQuick.Layouts
import KidsOS.Theme
import KidsOS.Localization

// spec §20/§35/vision-clarification §20: a Parent/Admin-only
// development diagnostic screen. Never shows raw screen content —
// only which engines are present and whether each is "real"
// (production, integrity-verified) or "Mock / Development" (spec §5
// of the vision clarification: the UI must never blur that line).
// Only reachable at all when Bridge.isChildAccount is false — see
// Main.qml's categories list.
Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spaceLg

        Text {
            text: LocalizationManager.tr("safety.devScreenTitle")
            font.family: Theme.fontDisplay
            font.weight: Font.Bold
            font.pixelSize: Theme.sizeTitle
            color: Theme.textPrimary
        }

        GridLayout {
            columns: 2
            columnSpacing: Theme.spaceLg
            rowSpacing: Theme.spaceSm

            Text { text: LocalizationManager.tr("safety.ocrLabel"); color: Theme.textSecondary }
            Text { text: LocalizationManager.tr("safety.statusAvailable"); color: Theme.textPrimary; font.weight: Font.Bold }

            Text { text: LocalizationManager.tr("safety.textEngineLabel"); color: Theme.textSecondary }
            Text { text: LocalizationManager.tr("safety.statusAvailable"); color: Theme.textPrimary; font.weight: Font.Bold }

            Text { text: LocalizationManager.tr("safety.visionEngineLabel") + " — NSFW"; color: Theme.textSecondary }
            Text { text: LocalizationManager.tr("safety.statusNotInstalled"); color: Theme.textPrimary; font.weight: Font.Bold }

            Text { text: LocalizationManager.tr("safety.visionEngineLabel") + " — Violence"; color: Theme.textSecondary }
            Text { text: LocalizationManager.tr("safety.statusNotInstalled"); color: Theme.textPrimary; font.weight: Font.Bold }

            Text { text: LocalizationManager.tr("safety.visionEngineLabel") + " — Self-harm"; color: Theme.textSecondary }
            Text { text: LocalizationManager.tr("safety.statusNotAvailable"); color: Theme.textPrimary; font.weight: Font.Bold }

            Text { text: LocalizationManager.tr("safety.internetDependencyLabel"); color: Theme.textSecondary }
            Text { text: LocalizationManager.tr("safety.internetDependencyNone"); color: Theme.textPrimary; font.weight: Font.Bold }
        }

        Text {
            Layout.topMargin: Theme.spaceMd
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "No vision-safety model is bundled with this build — the categories above show "
                  + "\"Not installed\" until an approved model.onnx is placed under "
                  + "/usr/lib/kidsos/models/vision-safety/ with a matching manifest. "
                  + "OCR and text-safety run against every sample regardless."
            font.family: Theme.fontInterface
            font.pixelSize: Theme.sizeCaption
            color: Theme.textSecondary
        }
    }
}

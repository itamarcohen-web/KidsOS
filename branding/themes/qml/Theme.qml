pragma Singleton
import QtQuick

// KidsOS Design System — single source of truth for color, type, spacing,
// radius, elevation and motion tokens. Every app (onboarding, launcher,
// settings, files) imports this instead of hard-coding values.
//
// Dark mode is a deliberately separate, hand-tuned palette (not an
// inversion) — see the `dark*` values below. Nothing outside this file
// should reference a raw hex color for anything Theme already exposes;
// `tests/validate_brand_colors.py` enforces this for the four KIDS
// brand hues specifically.
QtObject {
    id: theme

    // "light" | "dark" | "system". Sub-machine — dark mode may be pending
    // system dark-mode detection to seed a "system" value from KWin.
    property string mode: "light"
    // Set by the shell (LauncherBridge) if/when it can read the real
    // Plasma color-scheme preference; used only when mode === "system".
    property bool systemPrefersDark: false
    readonly property bool isDark: mode === "dark" || (mode === "system" && systemPrefersDark)

    // Toggled from Settings > Accessibility (apps/settings/qml/categories/
    // AccessibilityCategory.qml) and read by every entrance/transition
    // animation in the shared component library. Not yet auto-detected
    // from the system accessibility setting — see docs/KNOWN_LIMITATIONS.md.
    property bool reducedMotion: false

    // ---- KIDS logo palette (also doubles as the brand accent set) ----
    // Slightly brightened in dark mode to keep contrast/vibrancy against
    // the dark backgrounds below — same hues, tuned lightness.
    readonly property QtObject logo: QtObject {
        readonly property color k: theme.isDark ? "#FF6B70" : "#FF5A5F" // coral red
        readonly property color i: theme.isDark ? "#FFC233" : "#FFB400" // sunny amber
        readonly property color d: theme.isDark ? "#26D6BB" : "#00C2A8" // mint teal
        readonly property color s: theme.isDark ? "#5C9DFF" : "#3D8BFD" // sky blue
    }

    // Named aliases matching the product spec's token names 1:1.
    readonly property color KIDS_RED: logo.k
    readonly property color KIDS_YELLOW: logo.i
    readonly property color KIDS_TEAL: logo.d
    readonly property color KIDS_BLUE: logo.s

    // ---- Core palette ----
    readonly property color primary: logo.s
    readonly property color primaryPressed: theme.isDark ? "#3D7AE0" : "#2E6FD9"
    readonly property color secondary: logo.k
    readonly property color success: logo.d
    readonly property color warning: logo.i
    readonly property color error: theme.isDark ? "#FF6B74" : "#FF4757"

    readonly property color background: theme.isDark ? "#14161F" : "#F6F7FC"
    readonly property color surface: theme.isDark ? "#1E212E" : "#FFFFFF"
    readonly property color surfaceAlt: theme.isDark ? "#262A3A" : "#EEF1FA"
    readonly property color surfaceSunken: theme.isDark ? "#0F1117" : "#E4E8F5"
    readonly property color border: theme.isDark ? "#333850" : "#DCE1F0"
    readonly property color overlay: theme.isDark ? "#05060CE6" : "#141726CC"

    readonly property color textPrimary: theme.isDark ? "#F4F5FA" : "#1B1E2B"
    readonly property color textSecondary: theme.isDark ? "#A8AEC4" : "#5B6178"
    readonly property color textOnPrimary: "#FFFFFF"
    readonly property color textOnDark: "#FFFFFF"

    readonly property var avatarPalette: [logo.k, logo.i, logo.d, logo.s, "#A66BFF", "#FF7EB6"]

    // Icon container background (see branding/icons/README.md) — a
    // neutral chip every app-icon glyph sits on, independent of mode so
    // icons read consistently in a light or dark dock/launcher.
    readonly property color iconContainer: "#E8E8E8"

    // ---- Typography ----
    // Interface font: Rubik — friendly, rounded-leaning, full Latin/Hebrew/Arabic coverage.
    // Display font: Nunito (weight 900) — the KIDS wordmark and hero English
    // headings only; readability-first Rubik carries all body text.
    readonly property string fontInterface: "Rubik"
    readonly property string fontDisplay: "Nunito"
    readonly property int fontDisplayWeight: Font.Black // 900

    readonly property int sizeDisplay: 64
    readonly property int sizeH1: 40
    readonly property int sizeH2: 28
    readonly property int sizeH3: 22
    readonly property int sizeBodyLarge: 20
    readonly property int sizeBody: 17
    readonly property int sizeCaption: 14
    readonly property int sizeButton: 19

    // ---- Spacing scale ----
    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 16
    readonly property int spaceLg: 24
    readonly property int spaceXl: 32
    readonly property int spaceXxl: 48
    readonly property int spaceXxxl: 64

    // ---- Corner radius ----
    readonly property int radiusSm: 12
    readonly property int radiusMd: 20
    readonly property int radiusLg: 28
    readonly property int radiusPill: 999
    // Reference icon radius: 32px on a 128px canvas (see branding/icons/).
    readonly property real iconRadiusRatio: 32.0 / 128.0

    // ---- Elevation (used with QtQuick.Effects MultiEffect shadows) ----
    readonly property color shadowColor: theme.isDark ? "#000000" : "#1B1E2B"
    readonly property real shadowOpacityLow: theme.isDark ? 0.35 : 0.08
    readonly property real shadowOpacityMed: theme.isDark ? 0.5 : 0.14
    readonly property real shadowOpacityHigh: theme.isDark ? 0.6 : 0.22

    // ---- Motion ----
    readonly property int durationFast: 150
    readonly property int durationNormal: 250
    readonly property int durationSlow: 400
    readonly property int durationPage: 500
    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingEmphasized: Easing.OutBack

    // Touch target minimum (accessibility + "large touch-friendly controls")
    readonly property int touchTargetMin: 56
}

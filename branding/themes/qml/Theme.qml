pragma Singleton
import QtQuick

// KidsOS Design System — single source of truth for color, type, spacing,
// radius, elevation and motion tokens. Every app (onboarding, launcher,
// settings) imports this instead of hard-coding values.
QtObject {
    id: theme

    readonly property bool reducedMotion: false // bound to org.kde accessibility setting by the shell at runtime

    // ---- KIDS logo palette (also doubles as the brand accent set) ----
    readonly property QtObject logo: QtObject {
        readonly property color k: "#FF5A5F" // coral red
        readonly property color i: "#FFB400" // sunny amber
        readonly property color d: "#00C2A8" // mint teal
        readonly property color s: "#3D8BFD" // sky blue
    }

    // ---- Core palette ----
    readonly property color primary: logo.s
    readonly property color primaryPressed: "#2E6FD9"
    readonly property color secondary: logo.k
    readonly property color success: logo.d
    readonly property color warning: logo.i
    readonly property color error: "#FF4757"

    readonly property color background: "#F6F7FC"
    readonly property color surface: "#FFFFFF"
    readonly property color surfaceAlt: "#EEF1FA"
    readonly property color surfaceSunken: "#E4E8F5"
    readonly property color border: "#DCE1F0"
    readonly property color overlay: "#141726CC"

    readonly property color textPrimary: "#1B1E2B"
    readonly property color textSecondary: "#5B6178"
    readonly property color textOnPrimary: "#FFFFFF"
    readonly property color textOnDark: "#FFFFFF"

    readonly property var avatarPalette: [logo.k, logo.i, logo.d, logo.s, "#A66BFF", "#FF7EB6"]

    // ---- Typography ----
    // Interface font: Rubik — friendly, rounded-leaning, full Latin/Hebrew/Arabic coverage.
    // Display font: Baloo 2 — playful rounded display, used ONLY for the KIDS wordmark
    // and hero English headings; never for body text or non-Latin scripts.
    readonly property string fontInterface: "Rubik"
    readonly property string fontDisplay: "Baloo 2"

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

    // ---- Elevation (used with QtQuick.Effects MultiEffect shadows) ----
    readonly property color shadowColor: "#1B1E2B"
    readonly property real shadowOpacityLow: 0.08
    readonly property real shadowOpacityMed: 0.14

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

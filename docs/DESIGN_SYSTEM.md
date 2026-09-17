# KidsOS design system

Single source of truth: `branding/themes/qml/Theme.qml` (the `KidsOS.Theme`
QML singleton). Every value below is a property on that object —
nothing in an app should hard-code a hex color, pixel size, spacing
value, radius or animation duration.

## Brand palette (also the KIDS logo colors)

| Token | Hex | Use |
|---|---|---|
| `logo.k` Coral Red | `#FF5A5F` | Logo "K", secondary accent |
| `logo.i` Sunny Amber | `#FFB400` | Logo "I", warning tone |
| `logo.d` Mint Teal | `#00C2A8` | Logo "D", success tone |
| `logo.s` Sky Blue | `#3D8BFD` | Logo "S", **primary** interactive color |

## Neutrals

| Token | Hex |
|---|---|
| `background` | `#F6F7FC` |
| `surface` | `#FFFFFF` |
| `surfaceAlt` | `#EEF1FA` |
| `border` | `#DCE1F0` |
| `textPrimary` | `#1B1E2B` |
| `textSecondary` | `#5B6178` |

## Typography

Two families total:

- **Rubik** — interface font, all body/UI text, all three languages.
- **Baloo 2** — display font, KIDS wordmark + hero English headings only.

Type scale: `sizeDisplay 64` · `sizeH1 40` · `sizeH2 28` · `sizeH3 22` ·
`sizeBodyLarge 20` · `sizeBody 17` · `sizeCaption 14` · `sizeButton 19`
(all in px).

## Spacing & shape

Spacing scale: `xs 4 · sm 8 · md 16 · lg 24 · xl 32 · xxl 48 · xxxl 64`.
Corner radius: `sm 12 · md 20 · lg 28 · pill 999`. Minimum touch target:
`touchTargetMin 56px`.

## Motion

`durationFast 150ms · durationNormal 250ms · durationSlow 400ms ·
durationPage 500ms`. Standard easing is `OutCubic`; playful
"pop" interactions (avatar selection, PIN dot fill) use `OutBack`
(`easingEmphasized`) for a small bounce. `Theme.reducedMotion` is the
hook every `Behavior`/entrance-animation checks before animating (see
`docs/…#accessibility` in `ARCHITECTURE.md` and
`apps/common/qml/OnboardingPage.qml`).

## Component library (`KidsOS.Common`, `apps/common/qml/`)

`KidsLogo` · `KidsButton` (primary/secondary/ghost) · `KidsCard` ·
`ProgressDots` · `LanguageCard` · `AvatarTile` · `PinDots` · `PinKey` ·
`AppTile` · `OnboardingPage` (the shared full-screen scaffold every
onboarding step is built from: back button, step dots, content slot,
primary/secondary footer actions).

Every onboarding screen is `OnboardingPage { … }` plus content — this is
what keeps all eight steps visually and behaviorally consistent instead
of each screen reinventing navigation and spacing.

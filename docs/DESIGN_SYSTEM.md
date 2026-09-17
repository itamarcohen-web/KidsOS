# KidsOS design system

Single source of truth: `branding/themes/qml/Theme.qml` (the `KidsOS.Theme`
QML singleton). Every value below is a property on that object —
nothing in an app should hard-code a hex color, pixel size, spacing
value, radius or animation duration.
`tests/validate_brand_colors.py` enforces this mechanically for the four
brand hues specifically: they may only appear inside `Theme.qml` and
`branding/`.

## Brand palette (also the KIDS logo colors)

| Token | Hex (light) | Hex (dark) | Use |
|---|---|---|---|
| `logo.k` / `KIDS_RED` | `#FF5A5F` | `#FF6B70` | Logo "K", secondary accent |
| `logo.i` / `KIDS_YELLOW` | `#FFB400` | `#FFC233` | Logo "I", warning tone |
| `logo.d` / `KIDS_TEAL` | `#00C2A8` | `#26D6BB` | Logo "D", success tone |
| `logo.s` / `KIDS_BLUE` | `#3D8BFD` | `#5C9DFF` | Logo "S", **primary** interactive color |

Dark-mode brand colors are hand-brightened, not inverted — same hues,
tuned for contrast against a dark background. `Theme.KIDS_RED/YELLOW/
TEAL/BLUE` are exact-name aliases for `Theme.logo.k/i/d/s`, for callers
that want the token names as specified rather than the `logo.*` grouping.

## Neutrals

| Token | Light | Dark |
|---|---|---|
| `background` | `#F6F7FC` | `#14161F` |
| `surface` | `#FFFFFF` | `#1E212E` |
| `surfaceAlt` | `#EEF1FA` | `#262A3A` |
| `surfaceSunken` | `#E4E8F5` | `#0F1117` |
| `border` | `#DCE1F0` | `#333850` |
| `textPrimary` | `#1B1E2B` | `#F4F5FA` |
| `textSecondary` | `#5B6178` | `#A8AEC4` |
| `iconContainer` | `#E8E8E8` (mode-independent — see Icons below) |

`Theme.mode` is `"light" | "dark" | "system"`; `Theme.isDark` resolves
it (`"system"` uses `Theme.systemPrefersDark`, which the shell can set
from a real Plasma color-scheme read — not yet wired, see
`docs/KNOWN_LIMITATIONS.md`). Every token above is a *binding* on
`Theme.isDark`, so flipping `Theme.mode` re-themes every open window
live — see `docs/DESKTOP_SHELL.md`.

## Typography

Two families total:

- **Nunito**, weight 900 (Black) — display font. The KIDS wordmark only,
  plus hero English headings. Fallback chain: `Arial Rounded MT Bold,
  Arial, sans-serif`.
- **Rubik** — interface font, all body/UI text, all three languages.

Type scale: `sizeDisplay 64` · `sizeH1 40` · `sizeH2 28` · `sizeH3 22` ·
`sizeBodyLarge 20` · `sizeBody 17` · `sizeCaption 14` · `sizeButton 19`
(all in px).

## Spacing & shape

Spacing scale: `xs 4 · sm 8 · md 16 · lg 24 · xl 32 · xxl 48 · xxxl 64`.
Corner radius: `sm 12 · md 20 · lg 28 · pill 999`. Minimum touch target:
`touchTargetMin 56px`.

## The KIDS wordmark

`apps/common/qml/KidsLogo.qml` reproduces `branding/logo/kids-logo.svg`
exactly: same four colors, same per-letter rotation (K -6°, I +4°, D
-3°, S +6°) and baseline offsets, so the "alive" playful personality
matches the brand reference at any size. It always renders left-to-right
(`LayoutMirroring.enabled: false`) even inside a mirrored RTL window,
since it's a brand mark, not translated content. Two variants:
`"welcome"` (the one large central-branding moment — the desktop home
screen, onboarding, About page) and `"compact"` (app bars, Settings
sidebar) — see `branding/logo/README.md` for the full usage policy
("use the wordmark strategically, not on every screen").

## Icons

`branding/icons/` (installed app icons) and `apps/common/qml/AppTile.qml`
(in-app tiles) share one language: a neutral light-gray (`#E8E8E8`,
`Theme.iconContainer`) rounded-square container (`iconRadiusRatio`
32/128), a simple centered glyph, and a short brand-color accent bar —
see `branding/icons/README.md`.

## Elevation & motion

Shadows use `QtQuick.Effects.MultiEffect` with `Theme.shadowColor` /
`shadowOpacityLow/Med/High` (all mode-aware — dark mode uses stronger,
pure-black shadows since colored shadows read muddy on dark surfaces).

`durationFast 150ms · durationNormal 250ms · durationSlow 400ms ·
durationPage 500ms`. Standard easing is `OutCubic`; playful "pop"
interactions (avatar selection, PIN dot fill, appearance-mode cards) use
`OutBack` (`easingEmphasized`). `Theme.reducedMotion` (toggled from
Settings → Accessibility) is checked by every overlay/transition
`Behavior` in the shared component library — `OnboardingPage`, `Dock`,
`LauncherOverlay`, `SearchOverlay`, `NotificationCenter`,
`QuickSettingsPanel`. Small press/hover feedback (button scale, tile
shadow) intentionally isn't gated — see `docs/KNOWN_LIMITATIONS.md` for
the exact scoping.

## Component library (`KidsOS.Common`, `apps/common/qml/`)

**Onboarding-era:** `KidsLogo` · `KidsButton` (primary/secondary/ghost) ·
`KidsCard` · `ProgressDots` · `LanguageCard` · `AvatarTile` · `PinDots` ·
`PinKey` · `OnboardingPage`.

**Desktop shell (this milestone):** `AppTile` · `Dock` · `StatusCluster`
· `LauncherOverlay` · `SearchOverlay` · `NotificationCenter` ·
`QuickSettingsPanel` · `ToggleRow`. See `docs/DESKTOP_SHELL.md` for how
these compose into the desktop.

Every onboarding screen is `OnboardingPage { … }` plus content; every
settings category is a small component (`apps/settings/qml/categories/`)
sharing `PlaceholderCategory.qml`'s structural pattern where it isn't
functional yet — this is what keeps every screen visually and
behaviorally consistent instead of each one reinventing navigation,
spacing, and control styles.

## Window design

KidsOS's own apps (Onboarding, Launcher, Settings, Kids Files) share one
internal chrome pattern: `Theme.background`, an `H1`-weight title in the
top-left (mirrored in RTL) of the content area, `Theme.spaceXl` margins,
and the same card/button language throughout. **Native window
decoration** (the KWin title bar — minimize/maximize/close, corner
radius) is left at Kinoite's default Breeze theme rather than
re-skinned: Breeze already ships consistent rounded corners on Plasma 6,
and hand-authoring KWin/Aurorae theme files that couldn't be boot-tested
in this environment was judged riskier than leaving a known-good default
in place. See `docs/KNOWN_LIMITATIONS.md`.

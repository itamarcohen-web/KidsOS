# KIDS logo & brand palette

The KIDS wordmark is the primary brand asset for KidsOS. It is a brand
mark, not translated UI copy — it is always rendered as four uppercase
Latin letters, left-to-right, even inside a mirrored Hebrew/Arabic layout
(see `LayoutMirroring.enabled: false` on `apps/common/qml/KidsLogo.qml`).

## Visual reference

`kids-logo.svg` in this directory is the canonical brand reference:
four letters, each with a small independent rotation and baseline
offset so the mark feels "alive" rather than a rigid corporate
wordmark, while staying legible at any size. `apps/common/qml/KidsLogo.qml`
reproduces this exactly at runtime (same rotation degrees, same relative
baseline rise) rather than approximating it.

| Letter | Name        | Hex       | Rotation | Baseline |
|--------|-------------|-----------|----------|----------|
| K      | Coral Red   | `#FF5A5F` | -6°      | base     |
| I      | Sunny Amber | `#FFB400` | +4°      | raised   |
| D      | Mint Teal   | `#00C2A8` | -3°      | base     |
| S      | Sky Blue    | `#3D8BFD` | +6°      | raised   |

These four colors double as the system's brand accent palette
(`Theme.logo.k/i/d/s`, also exposed as `Theme.KIDS_RED/YELLOW/TEAL/BLUE`
in `branding/themes/qml/Theme.qml`) — used for avatar tints, selection
states, and the confetti on the onboarding finish screen, so the logo's
palette is felt throughout the OS, not just on the splash screen. In
dark mode these are hand-brightened (not blindly inverted) to keep the
same hues legible against a dark background — see `Theme.qml`.

Use the wordmark strategically, not on every screen: the desktop uses it
once as a central branding element; other surfaces (dock, settings, app
headers) use the compact mark or no logo at all.

## Typography

- **Display / logo font:** Nunito, weight 900 (Black) — playful, rounded,
  SIL OFL, Google Fonts. Fallback chain: `Arial Rounded MT Bold, Arial,
  sans-serif`. Used *only* for the "KIDS" wordmark and hero English
  headings, never for body text or non-Latin scripts.
- **Interface font:** Rubik — friendly, highly readable, full Latin/
  Hebrew/Arabic glyph coverage. Used for all other UI text in English,
  Hebrew and Arabic, keeping the interface to two font families total.

Font binary files are not vendored in this repository (see
`docs/KNOWN_LIMITATIONS.md`); the BlueBuild recipe fetches the
OFL-licensed `.ttf` files at build time (`recipes/build-kidsos-apps.sh`).
Both fonts are the same for every locale — no separate "display" font
per script.

## Files

- `kids-logo.svg` — full wordmark lockup, used on the welcome screen and
  marketing surfaces.
- `kids-mark.svg` — compact single-letter mark (gradient badge), used as
  the app/taskbar icon for the launcher and onboarding app.

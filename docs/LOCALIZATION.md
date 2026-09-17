# Localization

KidsOS ships English, Hebrew and Arabic from the start. No UI component
hard-codes a display string; every screen calls
`LocalizationManager.tr("key.path")`.

## How it works

- String tables live at `core/localization/strings/{en,he,ar}.json`, one
  flat-ish nested JSON tree per language, all three with **identical key
  structure** (enforced by `tests/validate_locales.py`).
- `core/localization/LocalizationManager.qml` is a QML singleton
  (`KidsOS.Localization`) that loads the active language's JSON at
  runtime via `XMLHttpRequest`, with English always loaded as a silent
  fallback for any missing key.
- `Localization.tr("onboarding.name.greeting", [name])` does `%1`-style
  positional substitution.
- `Localization.isRTL` / `Localization.layoutDirection` drive RTL layout
  (see below); `Localization.setLanguage("he" | "ar" | "en")` switches
  language instantly, no restart.

## Adding a language

1. Copy `core/localization/strings/en.json` to `<code>.json`, translate
   every value (never the keys).
2. Add `{ code, nativeName, direction }` to
   `LocalizationManager.supportedLanguages`.
3. Run `python3 tests/validate_locales.py` — it fails if the new file's
   keys don't exactly match `en.json`.

## RTL is a layout mode, not text alignment

Every app window sets:

```qml
LayoutMirroring.enabled: LocalizationManager.isRTL
LayoutMirroring.childrenInherit: true
```

on its root `Window`. Qt then mirrors anchors (`left`↔`right`),
`Row`/`RowLayout` item order, and horizontal positioning for every
descendant item automatically — components never special-case RTL
themselves. The one deliberate exception is `KidsLogo`
(`apps/common/qml/KidsLogo.qml`), which sets
`LayoutMirroring.enabled: false` on itself: "KIDS" is a brand mark, not
translated content, and must always read K-I-D-S left-to-right.

Icons that are directionally meaningless (settings gear, app glyphs) are
left as-is; only navigation chevrons (`onboarding/.../OnboardingPage.qml`
back arrow) explicitly swap glyph based on `isRTL`.

## Fonts

Rubik (interface) has full Latin/Hebrew/Arabic glyph coverage, so the
same font family is used for body text in all three languages — no
per-script font swapping, no missing-glyph boxes. See
`branding/logo/README.md` for font sourcing.

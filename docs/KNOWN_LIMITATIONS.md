# Known limitations

This is an honest account of what was and wasn't verified, and what was
deliberately left out, across both milestones so far. Read this before
assuming anything below "works" in the sense of "was seen running."

## Could not be executed in this development environment

This repository was authored on macOS, in a sandbox without `podman`,
`docker`, a Qt6/KDE Frameworks toolchain, `qmllint`, or KVM. As a direct
result, **none of the following were actually run**:

- Compiling the four Qt6/QML apps (`apps/onboarding`, `apps/launcher`,
  `apps/settings`, `apps/files`). The C++ and QML were written carefully
  and reviewed by hand against known-correct Qt6/QML APIs (including the
  Qt 6.4+ inline `component` syntax used in `Dock.qml`, and Qt 6.5+
  `QtQuick.Effects.MultiEffect`), but there is no substitute for a real
  compile + `qmllint` pass. **Run `cmake --build` on a Linux box with Qt6
  before trusting this code compiles cleanly.**
- The BlueBuild container image build (`recipes/recipe.yml` +
  `recipes/build-kidsos-apps.sh`).
- Generating an ISO or booting one in a VM — so dark mode, RTL, the
  dock/launcher/search/notifications/quick-settings overlays, and every
  item in `tests/checklist_manual_qa.md` have been reviewed by reading
  the code, not by seeing them render.
- The `.github/workflows/build.yml` CI workflow — verify its
  reusable-workflow reference against the current
  [BlueBuild template](https://github.com/blue-build/template).
- Fetching the Rubik/Nunito font files (`build-kidsos-apps.sh` does this
  via `curl` against GitHub — verify those raw-file URLs still resolve;
  Google Fonts repo layouts do change).

## What *was* validated here

- `tests/validate_recipe.py` — `recipe.yml` is syntactically valid YAML
  with the expected top-level keys and all referenced files exist.
- `tests/validate_locales.py` — `en.json`/`he.json`/`ar.json` are valid
  JSON with **identical key sets** (136 keys as of milestone 2), so no
  screen can end up missing a translation.
- `tests/validate_brand_colors.py` — the four KIDS brand hex codes never
  appear hard-coded outside `Theme.qml`/`branding/`.
- Brace/paren balance across all 36 `.qml` files; `.desktop`/`.service`
  files parse as valid INI with the required keys; every `qmldir` entry
  has a matching file on disk; every static (non-dynamically-concatenated)
  `LocalizationManager.tr()` key resolves against `en.json`.
- Manual review of every `.qml`/`.cpp`/`.sh`/`.yml` file for internal
  consistency (import statements, property names referenced across
  files, command names matching installed packages, systemd/desktop
  cross-references, etc.).

## Deliberately scoped-down decisions

- **KWin/Aurorae window-decoration theming was not attempted** (spec
  item 14, "Window Design"). KidsOS's own apps share one internal chrome
  pattern (see `docs/DESIGN_SYSTEM.md` → Window design), but the native
  title bar stays Kinoite's default Breeze — hand-authoring KWin config
  that couldn't be boot-tested risked a session-breaking change, which
  is worse than an honestly-scoped-down milestone. Same reasoning as
  milestone 1's Plasma-panel decision below.
- **Plasma "kiosk mode" still not attempted** — `kidsos-launcher` is the
  primary surface a child sees, but the default Plasma panel isn't
  suppressed at the Plasma-config level. See `docs/ROADMAP.md`.
- **Quick Settings' Wi-Fi/Bluetooth/Night Light are local UI state**, not
  wired to NetworkManager/BlueZ/night-color — only Dark Mode is a real,
  system-affecting toggle in this milestone. This was an explicit scope
  cut to keep the milestone's real backend work (account creation, PIN
  hashing, appearance persistence) verifiable by reading, rather than
  quietly shipping five different unverified D-Bus integrations.
- **9 of 13 Settings categories are structural placeholders**
  (`PlaceholderCategory.qml`) — Appearance, Language and Accessibility
  are the three made fully functional this milestone.
- **`Theme.systemPrefersDark`** (the "system" appearance option) isn't
  wired to a real Plasma color-scheme read; it currently behaves like
  Light. See `docs/ROADMAP.md`.
- **Reduced motion is manual**, not auto-detected from the system
  accessibility setting, and only gates the shell's larger
  overlay/transition animations (documented per-component in
  `docs/DESIGN_SYSTEM.md`) — small press/hover feedback still animates
  unconditionally, since WCAG's reduced-motion guidance targets large
  parallax/auto-play motion rather than a button's own press feedback.
- **Kids Files is a branded front door, not a file manager** — 8 location
  cards that open Dolphin at the right path (`FilesBridge::openLocation`).
  Building a from-scratch file browser was judged out of proportion to
  this milestone's UX-and-consistency goal.
- **No `.ts`/Qt Linguist localization pipeline** — a lightweight
  JSON-based runtime loader (`LocalizationManager.qml`) is used instead.
- **Font files are not vendored** — Rubik and Nunito are fetched at
  image-build time rather than committed as binary `.ttf` files.

## If you pick this up next

Start by actually compiling (`docs/BUILD.md` §2) on a Linux machine —
that will surface any QML/C++ mistakes fastest, long before attempting a
full OS image build. Pay particular attention to `Dock.qml`'s inline
`component DockButton: ...` syntax and the `QtQuick.Effects` imports
(`AppTile.qml`, `KidsCard.qml`) — both need Qt ≥ 6.4/6.5 respectively,
matching the `find_package(Qt6 6.5 ...)` floor already set in the root
`CMakeLists.txt`, but that floor has not been exercised by a real build.

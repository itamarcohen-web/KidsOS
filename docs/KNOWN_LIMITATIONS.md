# Known limitations of this milestone

This is an honest account of what was and wasn't verified, and what was
deliberately left out. Read this before assuming anything below "works"
in the sense of "was seen running."

## Could not be executed in this development environment

This repository was authored on macOS, in a sandbox without `podman`,
`docker`, a Qt6/KDE Frameworks toolchain, `qmllint`, or KVM. As a direct
result, **none of the following were actually run**:

- Compiling the three Qt6/QML apps (`apps/onboarding`, `apps/launcher`,
  `apps/settings`). The C++ and QML were written carefully and reviewed
  by hand against known-correct Qt6/QML APIs, but there is no substitute
  for a real compile + `qmllint` pass. **Run `cmake --build` on a Linux
  box with Qt6 before trusting this code compiles cleanly.**
- The BlueBuild container image build (`recipes/recipe.yml` +
  `recipes/build-kidsos-apps.sh`).
- Generating an ISO or booting one in a VM.
- The `.github/workflows/build.yml` CI workflow — its reusable-workflow
  reference should be checked against the current
  [BlueBuild template](https://github.com/blue-build/template) before
  relying on it.
- Fetching the Rubik/Baloo 2 font files (`build-kidsos-apps.sh` does this
  via `curl` against GitHub — verify those raw-file URLs still resolve;
  Google Fonts repo layouts do change).

## What *was* validated here

- `tests/validate_recipe.py` — `recipe.yml` is syntactically valid YAML
  with the expected top-level keys.
- `tests/validate_locales.py` — `en.json`/`he.json`/`ar.json` are valid
  JSON and have **identical key sets**, so no screen can end up missing a
  translation.
- Manual review of every `.qml`/`.cpp`/`.sh`/`.yml` file for internal
  consistency (import statements, property names referenced across
  files, command names matching installed packages, systemd unit
  cross-references, etc.).

## Deliberately scoped-down decisions

- **Plasma "kiosk mode" was not attempted.** `kidsos-launcher` runs
  full-screen as the primary surface a child sees, but the default
  Plasma desktop shell/panel is not suppressed or replaced at the
  Plasma-config level. Hand-authoring KDE `*rc` config files that alter
  Plasma's shell behavior without being able to boot-test them risked
  shipping a session-breaking config, which is a worse outcome than an
  honestly-scoped-down milestone. See `docs/ROADMAP.md`.
- **No `.ts`/Qt Linguist localization pipeline.** A lightweight
  JSON-based runtime loader (`LocalizationManager.qml`) was used instead
  — simpler to keep string-complete without a `lupdate`/`lrelease` build
  step, at the cost of losing Qt Linguist's translator tooling and
  plural-forms support. Documented as a real tradeoff, not an oversight.
- **Age screen uses individual ages 5–16**, not age *bands*. The brief
  didn't specify which; individual ages were chosen as the simpler,
  least-ambiguous option for a "how old are you?" prompt.
- **Font files are not vendored in the repository.** Rubik and Baloo 2
  are fetched at image-build time (see `build-kidsos-apps.sh`) rather
  than committed as binary `.ttf` files, to keep the repository free of
  large binaries and always pull the current OFL release.

## If you pick this up next

Start by actually compiling (`docs/BUILD.md` §2) on a Linux machine —
that will surface any QML/C++ mistakes fastest, long before attempting a
full OS image build.

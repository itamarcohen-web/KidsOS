# KidsOS architecture

## Layers

```
┌──────────────────────────────────────────────────────────────┐
│ KidsOS apps (Qt6 + QML)                                       │
│  onboarding · launcher · settings · files · approvals ·       │
│  parent-indicator · file-guard-prompt                         │
│  + kidsos-safety-agent (Qt6, headless, Child session only)     │
│    — see docs/SAFETY_AI.md                                    │
├──────────────────────────────────────────────────────────────┤
│ KidsOS services (Qt6 + QtDBus, root/system D-Bus)              │
│  kidsos-auth · kidsos-policy · kidsos-installer ·               │
│  kidsos-file-guard · kidsos-safety                              │
│  — see docs/SECURITY_ARCHITECTURE.md and docs/SAFETY_AI.md      │
├──────────────────────────────────────────────────────────────┤
│ Shared runtime  (apps/common, branding/themes, core/…)          │
│  KidsOS.Theme · KidsOS.Localization · KidsOS.Common              │
├──────────────────────────────────────────────────────────────┤
│ KDE Plasma 6 / KWin · polkit · PAM · fapolicyd · SDDM             │
├──────────────────────────────────────────────────────────────┤
│ Fedora Kinoite  (rpm-ostree, atomic updates, Flatpak)             │
└──────────────────────────────────────────────────────────────┘
```

KidsOS does not replace the Linux/Plasma foundation — it adds a
purpose-built first-run experience, login screen, home screen, and a
real Parent/Child account and permission system on top of it. Every
restriction on the Child account is enforced by standard Linux
mechanisms (`wheel` membership, polkit, PAM, fapolicyd), not just hidden
in the UI — see `docs/SECURITY_ARCHITECTURE.md`, which is the
authoritative reference for exact groups/services/policy files.

## Apps

Native Qt6/QML executables, each a thin `main.cpp` (QGuiApplication +
QQmlApplicationEngine) loading a `Main.qml` that lives on disk under
`/usr/share/kidsos/apps/<name>/qml/` (installed by CMake — see the root
`CMakeLists.txt`). None of them use Qt Resource System/qrc bundling; QML
is loaded straight from installed files, which keeps local development
fast (`QML2_IMPORT_PATH` / `KIDSOS_DEV_APP_QML_DIR` / `KIDSOS_DEV_LOCALES_PATH`
env vars point the engine at the source tree instead — see `docs/BUILD.md`).

| App | Binary | Runs as | Purpose |
|---|---|---|---|
| Onboarding | `kidsos-onboarding` | `kidsos-setup` (first boot only) | Parent + Child account creation wizard (10 screens) — see `docs/ACCOUNTS_AND_LOGIN.md` |
| Launcher | `kidsos-launcher` | Child | The KidsOS desktop: home, dock, launcher, search, notifications, quick settings — `docs/DESKTOP_SHELL.md` |
| Settings | `kidsos-settings` | Parent or Child | 13-category settings; shows "managed by parent" banners for a Child session |
| Kids Files | `kidsos-files` | Child | Branded front door onto the filesystem (Dolphin underneath) |
| App Requests (Approvals) | `kidsos-approvals` | Parent | Approve/deny Kids Store & external-file requests, revoke trust — `docs/TRUST_MODEL.md` |
| Parent Mode indicator | `kidsos-parent-indicator` | Parent | Small always-on-top badge + Switch User, autostarted instead of the launcher |
| App Guard prompt | `kidsos-file-guard-prompt` | Child | "Parent approval required" dialog, default handler for executable-ish MIME types |

## Shared runtime modules

Installed once, under `/usr/share/kidsos/qml/KidsOS/…`, and imported by
every app via `engine.addImportPath()` — including the SDDM login theme
(`branding/sddm-theme/kidsos/`), via `GreeterEnvironment=` in
`/etc/sddm.conf.d/kidsos-theme.conf`:

- **`KidsOS.Theme`** (`branding/themes/qml/Theme.qml`) — the design
  system: colors (incl. dark mode), type scale, spacing, radius, motion
  tokens. Single source of truth.
- **`KidsOS.Localization`** (`core/localization/`) — runtime string
  loading (see `docs/LOCALIZATION.md`).
- **`KidsOS.Common`** (`apps/common/qml/`) — the reusable component
  library, shared down to the login screen (`PinDots`/`PinKey`/`KidsCard`
  render identically in onboarding, the desktop, and SDDM).

## Session flow

1. **First boot only**: SDDM autologs into `kidsos-setup`
   (`/etc/sddm.conf.d/kidsos-setup-autologin.conf`), which runs only
   `kidsos-onboarding`. Finishing it creates the real Parent and Child
   Linux accounts via `kidsos-auth` and removes that autologin config.
2. **Every login after that**: the KidsOS SDDM theme
   (`branding/sddm-theme/kidsos/`) shows the Parent/Child account
   picker → real PAM authentication (password or PIN, both real Linux
   credentials) → normal SDDM session start.
3. `/etc/xdg/autostart/org.kidsos.session.desktop` runs
   `/usr/bin/kidsos-session-start`, which checks the logged-in account's
   **real group membership** (not a flag file): `wheel` → autostart
   `kidsos-parent-indicator` (leaving the normal Plasma desktop
   untouched); `kidsos-children` → autostart `kidsos-launcher`
   full-screen.
4. `kidsos-launcher`/`kidsos-settings` read `~/.config/kidsos/profile.json`
   (written by `kidsos-auth` at account-creation time) to personalize
   the greeting and set the active language.

See `docs/ACCOUNTS_AND_LOGIN.md` for the full flow and
`docs/SECURITY_ARCHITECTURE.md` for exactly what backs each step.

## Extension points (deliberately not built yet)

Each is a placeholder UI or a stable bridge interface today, so future
work slots in without touching this foundation — see
`docs/ROADMAP.md`:

- Kids Store — one demo app (Minecraft) exercises the real
  `InstallRequest` backend; no real catalog yet.
- Parent Cloud pairing — `ParentConnect.qml` mocks the pairing UX only.
- Screen Time / Web Protection / advanced App Approval policy UI /
  Device Management — Settings placeholder categories establish the
  pattern; `kidsos-policy`'s `appPolicies`/`managedSettings` schema is
  the natural backend for them.
- Safety AI: now implemented as of Milestone 4 (`kidsos-safety-agent` +
  `kidsos-safety` — see `docs/SAFETY_AI.md`), except Web Protection
  (URL/content filtering) specifically, which remains a placeholder.

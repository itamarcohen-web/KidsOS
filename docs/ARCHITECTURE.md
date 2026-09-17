# KidsOS architecture

## Layers

```
┌─────────────────────────────────────────────────────────┐
│ KidsOS apps (Qt6 + QML)                                  │
│  apps/onboarding   apps/launcher   apps/settings          │
├─────────────────────────────────────────────────────────┤
│ Shared runtime  (apps/common, branding/themes, core/…)    │
│  KidsOS.Theme · KidsOS.Localization · KidsOS.Common        │
├─────────────────────────────────────────────────────────┤
│ KDE Plasma 6 / KWin  (compositor, window mgmt, notifications)│
├─────────────────────────────────────────────────────────┤
│ Fedora Kinoite  (rpm-ostree, atomic updates, Flatpak)       │
└─────────────────────────────────────────────────────────┘
```

KidsOS does not replace the Linux/Plasma foundation — it adds a
purpose-built first-run experience and home screen on top of it, and
constrains the default account to a non-admin child user. Plasma/KWin
still provide window management and system services under the hood;
`kidsos-launcher` is the primary surface a child sees instead of the
default Plasma desktop shell (see "Session flow" below and
`docs/KNOWN_LIMITATIONS.md` for what's *not* yet suppressed at the
Plasma-shell level).

## Apps

Three native Qt6/QML executables, each a thin `main.cpp` (QGuiApplication
+ QQmlApplicationEngine) loading a `Main.qml` that lives on disk under
`/usr/share/kidsos/apps/<name>/qml/` (installed by CMake — see the root
`CMakeLists.txt`). None of them use Qt Resource System/qrc bundling; QML
is loaded straight from installed files, which keeps local development
fast (`KIDSOS_DEV_QML_DIR` / `KIDSOS_DEV_APP_QML_DIR` env vars point the
engine at the source tree instead — see `docs/BUILD.md`).

| App | Binary | Purpose |
|---|---|---|
| Onboarding | `kidsos-onboarding` | First-boot setup wizard (8 screens) |
| Launcher | `kidsos-launcher` | The KidsOS home screen / desktop |
| Settings | `kidsos-settings` | Placeholder settings shell |

## Shared runtime modules

Installed once, under `/usr/share/kidsos/qml/KidsOS/…`, and imported by
every app via `engine.addImportPath()`:

- **`KidsOS.Theme`** (`branding/themes/qml/Theme.qml`) — the design
  system: colors, type scale, spacing, radius, motion tokens. Single
  source of truth; nothing hard-codes a hex color or pixel size outside
  this file.
- **`KidsOS.Localization`** (`core/localization/`) — runtime string
  loading (see `docs/LOCALIZATION.md`).
- **`KidsOS.Common`** (`apps/common/qml/`) — the reusable component
  library (`KidsButton`, `KidsCard`, `OnboardingPage`, `AppTile`, …) that
  every screen in every app is built from, so the product feels like one
  designed system rather than three separate apps.

## Session flow

1. On login, `/etc/xdg/autostart/org.kidsos.session.desktop` (XDG
   autostart) runs `/usr/bin/kidsos-session-start`.
2. That wrapper checks `~/.config/kidsos/onboarding-complete`:
   - **absent** → launches `kidsos-onboarding` (full-screen).
   - **present** → launches `kidsos-launcher` (full-screen).
3. `ProfileBridge` (in the onboarding app) writes that flag, plus
   `~/.config/kidsos/profile.json` (name, avatar, age, language) and a
   salted-SHA-256-hashed child PIN, when the child finishes the "Finish"
   screen.
4. `kidsos-launcher` reads `profile.json` (via `LauncherBridge`) to
   personalize the greeting and to set the active language before its
   window is shown.

## Non-admin child account

`kidsos-firstboot.service` (a system `oneshot` unit, gated by
`ConditionPathExists=!/var/lib/kidsos/firstboot-done`) runs
`core/configuration/scripts/create-child-account.sh` once, which creates
a `kid` user that is **not** a member of `wheel` or any sudoers-equivalent
group. `core/configuration/polkit/10-kidsos-child-restrictions.rules`
adds an explicit polkit deny-list (package management, user
administration, disk mounting, systemd unit management, …) for that
account as a second layer of defense. See `docs/ROADMAP.md` for the
planned real Parent PIN / parent-authentication system that will sit
above this.

## Extension points (deliberately not built yet)

Each is a placeholder UI or a stable bridge interface today, so future
work slots in without touching this foundation — see
`docs/ROADMAP.md`:

- Kids Store — currently a "coming soon" dialog on the home screen.
- Parent Cloud pairing — `ParentConnect.qml` mocks the pairing UX only.
- Screen Time / Parent Controls / Safety AI / Web Protection / External
  App Approval — not represented in the UI yet; `ProfileBridge` and
  `LauncherBridge` are the natural place to add their client-side hooks.

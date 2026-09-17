# The KidsOS desktop shell

This milestone builds the complete child desktop experience on top of
milestone 1's foundation. Per the architecture requirement to keep the
shell modular (not one enormous source file), it's composed of
independent, reusable components in `apps/common/qml/`, each with one
job, wired together by `apps/launcher/qml/Main.qml`:

| Component | File | Responsibility |
|---|---|---|
| Dock | `Dock.qml` | Bottom navigation: Apps, Search, pinned apps, notifications bell (unread badge), status cluster |
| StatusCluster | `StatusCluster.qml` | Wi-Fi/Bluetooth/battery/clock; tapping opens Quick Settings |
| LauncherOverlay | `LauncherOverlay.qml` | Full-screen launcher: search, recently-used, 8 categories, card grid |
| SearchOverlay | `SearchOverlay.qml` | System-wide search across apps + Settings categories (+ files, model-ready) |
| NotificationCenter | `NotificationCenter.qml` | Slide-in panel: grouped, dismiss, clear all, unread dot |
| QuickSettingsPanel | `QuickSettingsPanel.qml` | Wi-Fi/Bluetooth/Dark Mode/Night Light/Volume — large toggles |
| ToggleRow | `ToggleRow.qml` | Shared large switch row, used by QuickSettingsPanel and Settings' Accessibility category |
| AppTile | `AppTile.qml` | The one app-icon tile used everywhere (home, launcher, Kids Files, search results) |

`apps/launcher/qml/Main.qml` owns exactly one thing beyond wiring: the
**app registry** (`window.apps`) — id, launch command, category, and
brand tint for every default app. Every other component (dock pinned
row, launcher grid, search index, home screen's "frequently used") reads
from that one array via `appsForUi` (the same array with labels already
resolved through `LocalizationManager.tr`), so there is exactly one
place that knows what apps exist.

## Data flow for a click

1. User taps an `AppTile` (home row, launcher grid, or a search result).
2. The tile emits `activated()`.
3. The owning screen calls `window.launch(app)`, which either opens the
   `comingSoon` dialog (placeholder apps: Kids Store, Games, School,
   Help, KidsOS Updates) or calls `Bridge.launchCommand(cmd, args)`
   (`LauncherBridge::launchCommand`, a `QProcess::startDetached`) and
   records the app in `recentIds` for the launcher's "Recently used" row.

## Dark mode

`Theme.mode` (`"light" | "dark" | "system"`) lives in the one shared
`Theme.qml` singleton, so setting it from **either** Quick Settings or
Settings → Appearance instantly re-themes every open KidsOS window,
because every color in every component is a binding that reads
`Theme.isDark`, not a value copied at startup. It's persisted via
`LauncherBridge`/`SettingsBridge` → `~/.config/kidsos/settings.json`, so
both apps stay in sync and it survives a restart. See
`docs/DESIGN_SYSTEM.md` for the actual light/dark token values.

## What's mocked in this milestone

- **Notifications** (`window.notifications` in `apps/launcher/qml/Main.qml`)
  are static mock data, per the product brief. No real update service or
  parent connectivity backs them yet.
- **Wi-Fi/Bluetooth/Night Light toggles** in Quick Settings are local UI
  state, not wired to NetworkManager/BlueZ/night-color. Dark Mode is the
  one fully real toggle there.
- **Kids Files** is a branded front door (8 large location cards) that
  opens Dolphin at the right path — not a from-scratch file manager.

See `docs/ROADMAP.md` for what's next.

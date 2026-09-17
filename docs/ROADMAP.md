# Roadmap (explicitly out of scope so far)

Per the product brief, these are intentionally **not** implemented yet —
only placeholders or stable extension points exist for them:

| Feature | Current state | Where it plugs in |
|---|---|---|
| Kids Store | "Coming soon" dialog, reachable from the home screen, launcher grid ("Internet" category) and search | `apps/launcher/qml/Main.qml` (`comingSoon` dialog, `store` app entry) |
| Parent Cloud / Parent App pairing | Mocked QR + pairing code, fake "connected" state | `apps/onboarding/qml/screens/ParentConnect.qml` |
| Parent PIN / parent authentication | Not implemented — only the **child** PIN exists | `ProfileBridge::setChildPin` is deliberately separate from any future parent credential |
| Screen Time | Not implemented | `LauncherBridge`/`ProfileBridge` are the natural place for a client-side hook |
| Parent Controls / External App Approval | Not implemented | Settings' placeholder categories (`PlaceholderCategory.qml`) establish the visual pattern |
| Safety AI / Screen Analysis / Web Protection | Not implemented | — |
| Real networking for parent pairing | Not implemented | `ParentConnect.qml`'s mock connect sequence marks exactly where a real pairing protocol call would go |
| Real parent-approved notifications | Mock data only (`window.notifications` in `apps/launcher/qml/Main.qml`) | See `docs/DESKTOP_SHELL.md` |

## Desktop shell follow-ups (this milestone's scope)

- **Wire Quick Settings' Wi-Fi/Bluetooth/Night Light** to real
  NetworkManager (`org.freedesktop.NetworkManager` D-Bus), BlueZ, and a
  night-color backend (`kwin`'s built-in night color via its D-Bus
  interface). Only Dark Mode is real today; see `docs/DESKTOP_SHELL.md`.
- **System-wide search's file results** (`SearchOverlay.filesModel`) —
  the component already accepts a files model and renders it identically
  to apps/settings results; nothing populates it yet (would need a
  lightweight indexer, e.g. over `~/Documents`, `~/School`, etc.).
- **`Theme.systemPrefersDark`** isn't wired to a real Plasma color-scheme
  read yet, so Settings → Appearance → "Match system" currently behaves
  like Light. Needs a small C++ hook (e.g. watching
  `org.kde.kdeglobals`'s `[General] ColorScheme` or `KColorSchemeManager`)
  in one of the bridges.
- **`Theme.reducedMotion`** is a manual toggle in Settings → Accessibility
  today, not auto-detected from the system accessibility setting.
- **KWin/Aurorae window-decoration theming** ("Window Design" item 14) —
  deliberately not attempted; see `docs/KNOWN_LIMITATIONS.md` for why.
- Wire the remaining 9 Settings placeholder categories (Internet, Sound,
  Bluetooth, Display, Keyboard, Mouse, Accounts, Storage, Apps) to real
  functionality — each already has a consistent home via
  `PlaceholderCategory.qml`.
- Persist the selected UI language across app restarts the same way
  appearance mode is persisted now (`settings.json`) — currently only
  onboarding's one-time `profile.json` write does this.

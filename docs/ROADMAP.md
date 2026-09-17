# Roadmap (explicitly out of scope for this milestone)

Per the product brief, this milestone is the OS foundation and child UX
only. These are intentionally **not** implemented — only placeholders or
stable extension points exist for them:

| Feature | Current state | Where it plugs in |
|---|---|---|
| Kids Store | "Coming soon" dialog on the home screen | `apps/launcher/qml/Main.qml` (`comingSoon` dialog, `store` app entry) |
| Parent Cloud / Parent App pairing | Mocked QR + pairing code, fake "connected" state | `apps/onboarding/qml/screens/ParentConnect.qml` |
| Parent PIN / parent authentication | Not implemented — only the **child** PIN exists | `ProfileBridge::setChildPin` is deliberately separate from any future parent credential |
| Screen Time | Not implemented | `LauncherBridge`/`ProfileBridge` are the natural place for a client-side hook |
| Parent Controls / External App Approval | Not implemented | Settings placeholder sections (`apps/settings/qml/Main.qml`) establish the visual pattern |
| Safety AI / Screen Analysis / Web Protection | Not implemented | — |
| Real networking for parent pairing | Not implemented | `ParentConnect.qml`'s mock connect sequence marks exactly where a real pairing protocol call would go |

## Smaller near-term follow-ups

- Persist the selected UI language across app restarts (currently
  session-only outside of onboarding's `profile.json`, which the
  launcher reads once at startup).
- A Plasma "kiosk mode" pass to actually hide the default Plasma
  panel/widgets for the child account (see
  `docs/KNOWN_LIMITATIONS.md` — deliberately not attempted this
  milestone since it couldn't be tested here).
- Wire `kidsos-settings`' placeholder sections (Profile, Display &
  Accessibility, Sound, About) to real functionality.
- A real font-scaling / high-contrast toggle backed by `Theme.qml`
  (today `Theme.reducedMotion` exists as a hook but nothing sets it from
  the system accessibility settings yet).

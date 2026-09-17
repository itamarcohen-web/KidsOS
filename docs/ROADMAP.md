# Roadmap (explicitly out of scope so far)

Per the product brief, these are intentionally **not** implemented yet —
only placeholders or stable extension points exist for them:

| Feature | Current state | Where it plugs in |
|---|---|---|
| Kids Store real catalog | One demo app ("Minecraft") exercises the real `InstallRequest` flow end to end | `apps/launcher/qml/Main.qml` (`storeDialog`), `kidsos-installer` |
| Parent Cloud / Parent App pairing | Mocked QR + pairing code, fake "connected" state | `apps/onboarding/qml/screens/ParentConnect.qml` |
| Screen Time | Not implemented | Settings placeholder category; `kidsos-policy`'s schema is the natural backend |
| Safety AI / Screen Analysis / Web Protection | Not implemented | — |
| Advanced App Approval *policy* UI (pre-authorizing categories/apps in advance, vs. reactive approve/deny) | Not implemented — the reactive flow (spec §16) *is* implemented (`kidsos-approvals`) | `kidsos-policy::SetAppPolicy` already exists as the backend hook |
| External File Approval policy UI | Reactive flow implemented (`kidsos-file-guard-prompt` → `kidsos-approvals`); no *proactive* per-source-URL policy UI yet | `kidsos-policy` |
| Device Management | Not implemented | — |
| Real parent-approved notifications | Mock data only (`window.notifications` in `apps/launcher/qml/Main.qml`) | See `docs/DESKTOP_SHELL.md` |

## Security/account follow-ups (this milestone's scope)

- **`Theme.systemPrefersDark`**, Quick Settings' Wi-Fi/Bluetooth/Night
  Light, and the 9 remaining Settings placeholder categories: same gaps
  as before — see `docs/DESKTOP_SHELL.md`.
- **Async D-Bus calls in onboarding** — `ParentPassword.qml`/
  `PinSetup.qml` call `kidsos-auth` synchronously; fine in practice
  (`useradd`/`chpasswd` are fast) but a future pass could make these
  properly async so the "Creating account…" state visibly renders.
- **`Theme.reducedMotion`** is a manual Settings toggle, not yet
  auto-detected from the system accessibility setting or persisted
  across restarts.
- **KWin/Aurorae window-decoration theming** — still not attempted; see
  `docs/KNOWN_LIMITATIONS.md`.
- **`SearchOverlay.filesModel`** still unpopulated (no file indexer yet).
- **Async/queued audit log review UI** — entries go to the systemd
  journal (`journalctl KIDSOS_AUDIT=1`); there's no in-app viewer for a
  Parent yet, only the raw journal.
- **fapolicyd/PAM/SDDM theme verification** — this milestone's biggest
  gap: see `docs/KNOWN_LIMITATIONS.md`'s dedicated section. Everything
  here is architecturally real (no fake checks, no hidden bypass
  passwords) but literally could not be exercised against a running
  Linux system in this development environment.
- **`ChangeChildPin`/`SetAppPolicy`/`SetSettingManaged`** exist in the
  services but have no UI wired to call them yet (e.g. no "change your
  child's PIN" button in Settings) — the D-Bus contract is ready for one.

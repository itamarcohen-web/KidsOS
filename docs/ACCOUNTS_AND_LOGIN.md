# Accounts, onboarding, and login

## First-boot flow (replaces milestone 1's single-account flow)

```
1. Welcome
2. Language
3. Parent account (name, username, password, confirm)
4. Child profile (name, avatar, age)
5. Child PIN (create + confirm — this becomes the child's real Linux password)
6. Parent connection placeholder  (unchanged from milestone 1 — still mocked)
7. Setup complete
```

This runs as a dedicated **`kidsos-setup`** system user (not root, not
any real account — created by the image build, `nologin` shell, no
password), started as an autologin SDDM session the very first boot
only. `kidsos-setup` has no privileges of its own; it talks to
`kidsos-auth` over D-Bus to actually create the Parent and Child
accounts (see `docs/SECURITY_ARCHITECTURE.md`). Running the *GUI* as an
unprivileged user while the *account creation* happens in a root D-Bus
service is deliberate — a compromised or buggy QML app should not be
able to do anything more dangerous than call two narrowly-scoped D-Bus
methods.

Once `kidsos-auth::CreateChildAccount` succeeds and the onboarding app
calls `MarkFirstBootComplete`, `kidsos-setup`'s autologin is disabled
(`sddm.conf`'s `[Autologin]` User= is unset by a small script) and the
system reboots into the normal KidsOS login screen. This mirrors how
Fedora's own `initial-setup`/Anaconda-adjacent tools behave: a
throwaway setup session, then a real login screen.

## Login screen (SDDM QML theme, `branding/sddm-theme/kidsos/`)

Two-step, card-based, matching `apps/common/qml/`'s visual language
(reusing `Theme.qml` tokens directly — the SDDM theme is QML too, so it
imports the same `KidsOS.Theme`/`KidsOS.Localization` modules installed
system-wide):

1. **Who's using KIDS?** — one card per real account SDDM's
   `userModel` reports, each showing the account's display name and
   avatar. Parent card uses the compact KIDS mark; child cards use the
   avatar chosen in onboarding (read from `profile.json` via a small
   context property the theme's C++-free QML populates by reading the
   same file `LauncherBridge` reads).
2. **Enter credentials** — Parent gets a password field (masked,
   `echoMode: TextInput.Password`); Child gets the `PinDots`/`PinKey`
   component pair reused verbatim from `apps/common/qml/` (SDDM's QML
   engine can import the same installed `KidsOS.Common` module). Both
   call `sddm.login(username, secret, sessionIndex)` — SDDM's own QML
   API — which goes through the exact same PAM stack either way
   (`pam_unix` + `pam_faillock`; no branching logic needed since the
   child's PIN *is* their Linux password, see
   `docs/SECURITY_ARCHITECTURE.md`).

On `sddm.loginFailed`, show one friendly line instead of SDDM's raw PAM
text — `"That PIN doesn't look right"` for a child card,
`"That password doesn't look right"` for the parent card (spec §10:
never reveal *why* — same message whether the account doesn't exist,
faillock has kicked in, or the secret is simply wrong).

## Account switching

Both the child desktop (`Dock`) and a small "Parent Mode" indicator on
the parent desktop expose **Switch user**, which calls
`kidsos-auth::SwitchToGreeter()` → `org.freedesktop.DisplayManager`'s
`SwitchToGreeter` (the standard cross-desktop display-manager D-Bus
spec SDDM implements) — this locks the current session and starts a
**new** greeter session on the same seat. Selecting any account from
that greeter goes through the exact same PAM authentication as a fresh
boot; there is no "trusted because you were already logged in"
shortcut. The previous session keeps running in the background (fast
user switching), reachable again the same way.

## What changed vs. milestone 1

- `ProfileBridge::setChildPin` (a local salted-SHA-256 JSON file) is
  **removed**. The child's PIN is now their real Linux account
  password, set once via `kidsos-auth::CreateChildAccount` during
  onboarding and changeable later only via
  `kidsos-auth::ChangeChildPin` (Parent-authenticated).
- `kidsos-firstboot.service` (milestone 1's automatic, no-UI child
  account creation) is **removed** — account creation is now always
  explicit, through onboarding, because there are now two accounts to
  create and the Parent's real password can't be invented by a script.

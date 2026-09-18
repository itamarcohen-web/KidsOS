# KidsOS security architecture

This is the authoritative reference for the family account/permission
system: exact group names, file paths, D-Bus interfaces, and PAM stack
changes. Every service implementation follows this document; if code and
this doc ever disagree, this doc is what a reviewer should trust was
*intended* (see `docs/KNOWN_LIMITATIONS.md` for what's unverified).

## Design principle

**Enforcement happens at the Linux layer, not the UI layer.** Every
restriction described below still holds if the child opens a terminal,
edits a `.desktop` file, renames a file, or calls a binary directly. The
KidsOS QML apps are conveniences on top of real `wheel`-membership,
polkit, PAM, and fapolicyd decisions — never the decision-makers
themselves.

## Accounts & groups

| Group | Members | Grants |
|---|---|---|
| `wheel` | Parent account(s) | Full sudo/administrative rights (Fedora default) |
| `kidsos-children` | Child account(s) | Nothing by itself — a *marker* group other policy (PAM, polkit, fapolicyd) keys off of |
| `kidsos-service` | The four service daemons run as this system user where they don't need to be root outright (`kidsos-policy`, read paths of `kidsos-installer`) | Read access to policy/request stores; **not** membership in `wheel` |

The Parent account is a completely ordinary Fedora administrator: real
`useradd` + `usermod -aG wheel`, real shadow password via `chpasswd`,
real sudo. Nothing about "Parent" is a KidsOS invention — it's just
what the account already was in milestone 1's created "kid" account
*not* getting `wheel`, now named and explained.

The Child account is created the same way, explicitly **without** `-aG
wheel`, plus membership in `kidsos-children` (a plain marker group,
`groupadd --system kidsos-children`, already added in milestone 1).

## Authentication

| Who | Credential | Enforced by |
|---|---|---|
| Parent | Real Linux account password | Standard `pam_unix.so` — no changes |
| Child | Real Linux account password, but numeric and short (the "PIN" the UI shows) | Standard `pam_unix.so` **+ `pam_faillock.so`** (lockout after repeated failures — mitigates the reduced entropy of a numeric password) |

Both credentials are set via `chpasswd` (through `kidsos-auth`, see
below), which routes through the system's real hashing configuration
(SHA-512 crypt via libxcrypt on Fedora) — nothing is ever written to
disk as plaintext, and there is exactly **one** authentication system
(PAM + shadow), not a parallel KidsOS-level password store. The "PIN"
is a UX framing (a 4-digit pad instead of a text field) over a real
Linux password, not a separate credential.

Fedora manages `/etc/pam.d/system-auth`/`password-auth` through
**`authselect`**, not hand-edited files (authselect regenerates and
warns about/reverts manual edits) — so lockout is enabled the
Fedora-native way, as a build step (`recipes/build-kidsos-apps.sh`):

```
authselect enable-feature with-faillock
```

which is authselect's own built-in feature for exactly this
(`pam_faillock.so`, deny=3 by default). This covers SDDM, `su`, `login`,
polkit's own PAM check, etc. uniformly, system-wide, without KidsOS
touching PAM stack files directly — see
`docs/KNOWN_LIMITATIONS.md`: this must still be verified on a real
install (does the base Kinoite image already have a custom authselect
profile active, does `with-faillock` compose cleanly with it).

## D-Bus services

Four separate root-owned system services (per spec: "do not combine
everything into one daemon"), each a small Qt6/QtDBus C++ binary under
`core/services/<name>/`, each with its own systemd unit, D-Bus
activation file, and D-Bus access-control file
(`/usr/share/dbus-1/system.d/org.kidsos.<Name>1.conf`) so only the
intended callers can invoke sensitive methods.

### `kidsos-auth` — `org.kidsos.Auth1` (`/org/kidsos/Auth1`)

Account/session logic. Runs as root (it calls `useradd`/`chpasswd`,
which need root).

- `CreateParentAccount(name, username, password) -> success: bool` —
  callable **only** during first boot (checked against
  `/var/lib/kidsos/firstboot-done` — refuses once that flag exists) or
  by a caller already in `wheel` (polkit action
  `org.kidsos.auth.create-account`, `auth_admin_keep`).
- `CreateChildAccount(name, username, pin, avatarId, age) -> success: bool`
  — same gating as above.
- `ChangeChildPin(username, newPin) -> success: bool` — polkit action
  `org.kidsos.auth.manage-child`, requires **Parent** authentication
  (`auth_admin`, not `auth_self`) every time, no caching.
- `SwitchToGreeter() -> success: bool` — thin wrapper around
  `org.freedesktop.DisplayManager`'s `SwitchToGreeter`, exposed here so
  the child UI never talks to the display-manager bus directly.

D-Bus policy (`org.kidsos.Auth1.conf`): `CreateParentAccount`/
`CreateChildAccount` are allowed only from the dedicated
`kidsos-setup` system user the firstboot session runs as (see
`docs/ACCOUNTS_AND_LOGIN.md`); everything else requires the calling
process to pass its normal polkit check.

### `kidsos-policy` — `org.kidsos.Policy1` (`/org/kidsos/Policy1`)

Read-mostly policy decisions, backed by
`/etc/kidsos/policy.json` (root:kidsos-service, mode 0640 — children
cannot read or write it directly; only queryable through this service).

- `GetAppPolicy(appId) -> "auto" | "ask_parent" | "blocked"`
- `IsSettingParentManaged(settingId) -> bool`
- `SetAppPolicy(appId, policy)` / `SetSettingManaged(settingId, bool)` —
  polkit action `org.kidsos.policy.manage`, `auth_admin` (Parent only).

Runs as the unprivileged `kidsos-service` user (it only needs read
access to its own state file plus polkit for writes) — deliberately
**not** root, since it never touches accounts or installs anything
itself.

### `kidsos-installer` — `org.kidsos.Installer1` (`/org/kidsos/Installer1`)

The privileged installation workflow (spec §24). Runs as root (actual
package/Flatpak installation needs it), but every mutating call is
polkit-gated so the *decision* to install still requires Parent
authentication even though the *daemon* has root.

- `SubmitInstallRequest(childId, appId, appName, source, permissions) -> requestId`
  — Kids Store path. No polkit check (any child can *request*).
- `SubmitExternalInstallRequest(childId, filePath) -> requestId` —
  computes SHA-256 itself (never trusts a hash passed in), captures
  file type/size/source-URL-if-xattr-present. No polkit check for
  submitting.
- `ApproveRequest(requestId) -> success: bool` / `DenyRequest(requestId)`
  — polkit action `org.kidsos.installer.approve`, `auth_admin` (Parent
  password required every time — not cached, per spec §27).
- `ListRequests(childId) -> [InstallRequest]`
- `RevokeTrust(requestId) -> success: bool` — same polkit action.

On `ApproveRequest` for an external file: re-hashes the file **at
approval time** and again immediately before install, compares both to
the hash captured at submission (spec §25 — "if the file changes after
approval, reject"), then calls `kidsos-file-guard`'s `TrustFile` method
to allowlist the exact hash before actually installing/enabling
execution. See `docs/TRUST_MODEL.md`.

Backing store: SQLite at `/var/lib/kidsos/installer/requests.db`
(`QSQLITE`, ships with Qt6, no extra dependency) — see
`core/services/kidsos-installer/RequestStore.h`.

### `kidsos-file-guard` — `org.kidsos.FileGuard1` (`/org/kidsos/FileGuard1`)

External-application trust enforcement (spec §17–22). Two layers:

1. **fapolicyd** (a real, existing Fedora package — kernel-level
   `fanotify`-based exec allowlisting) is the actual enforcement:
   default-deny execution for anything not in its trust database, for
   any process whose executing user is in `kidsos-children`. This is
   what makes bypass-via-terminal/rename/symlink/copy impossible — see
   `docs/TRUST_MODEL.md` for exactly why.
2. `kidsos-file-guard` (root, since it edits fapolicyd's trust files and
   reloads it) is the thin management layer:
   - `TrustFile(hash, path) -> success` — appends `<path> size <n> sha256 <hash>`
     to `/etc/fapolicyd/trust.d/kidsos-approved.trust`, runs
     `fagenrules --load` to reload. Callable only by `kidsos-installer`
     (D-Bus policy restricts the sender to that service's user).
   - `RevokeFile(hash) -> success` — removes the matching line, reloads.
   - `IsTrusted(hash) -> bool` — for the Kids Files / launcher UI to show
     accurate "blocked" state without duplicating fapolicyd's own logic.

A small GUI helper, `kidsos-file-guard-prompt` (registered as the
default handler for executable-ish MIME types — see
`docs/TRUST_MODEL.md`), shows the friendly "Parent approval required"
dialog and calls `SubmitExternalInstallRequest` — but it is **not**
what blocks execution; fapolicyd already has.

### `kidsos-safety` — `org.kidsos.Safety1` (`/org/kidsos/Safety1`)

The privileged half of the Local Safety AI System (Milestone 4) — full
pipeline description in `docs/SAFETY_AI.md`. Runs unprivileged as
`kidsos-service`, same as `kidsos-policy`. Owns
`/var/lib/kidsos/safety/events.db` and `/etc/kidsos/safety-policy.json`;
`kidsos-safety-agent` (which runs *inside the Child's own session*,
since XDG portal screen capture has to be requested from there) never
touches either file directly — only `ReportEvent`/`Heartbeat` over
D-Bus. `ReportEvent` additionally rejects any caller whose uid is in
`wheel` (i.e. a Parent session can't be mistaken for, or inject events
as, the Child), on top of the system D-Bus policy restricting the bus
name. `GetRecentEvents`/`SetThreshold` are polkit-gated
(`org.kidsos.safety.review` / `org.kidsos.safety.manage`,
`auth_admin`) exactly like `kidsos-policy`'s Parent-only calls.

## Polkit actions

`core/configuration/polkit/actions/org.kidsos.*.policy` (installed to
`/usr/share/polkit-1/actions/`):

| Action ID | Used for | Implicit auth |
|---|---|---|
| `org.kidsos.auth.create-account` | Creating accounts outside first-boot | `auth_admin_keep` |
| `org.kidsos.auth.manage-child` | Changing a child's PIN/profile | `auth_admin` |
| `org.kidsos.policy.manage` | Changing app/setting policy | `auth_admin` |
| `org.kidsos.installer.approve` | Approving/denying/revoking install requests | `auth_admin` |

`auth_admin` (not `auth_admin_keep`) is used everywhere a "Parent must
approve *this specific thing*" matters (spec §27: "do not cache/skip
authentication for approvals") — polkit will re-prompt for the password
every time rather than remembering it for a grace period.

## What child accounts categorically cannot do (Linux-enforced, not UI-hidden)

- `sudo` anything — not in `wheel`, and no `/etc/sudoers.d/` entry.
- Edit `/etc/kidsos/policy.json` — file permissions (0640, root:kidsos-service).
- Stop/disable `kidsos-*.service` — `systemctl` unit file permissions +
  polkit's default policy already requires `auth_admin` for
  `org.freedesktop.systemd1.manage-units` for non-wheel users (milestone
  1's `10-kidsos-child-restrictions.rules` makes this explicit/defense-in-depth).
- Execute an untrusted binary/script/AppImage/`.deb`/`.rpm` — fapolicyd,
  regardless of path, name, or invocation method.
- Read/write another user's home directory — standard Unix permissions
  (`0700` home dirs, Fedora default).

See `docs/TRUST_MODEL.md` for the file-trust state machine and
`docs/ACCOUNTS_AND_LOGIN.md` for the onboarding/login flow this backs.

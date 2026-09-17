# Known limitations

This is an honest account of what was and wasn't verified, and what was
deliberately left out, across all three milestones so far. Read this
before assuming anything below "works" in the sense of "was seen
running." **Milestone 3 (the family account/permission system) is the
most security-critical work in this repository and the least
verifiable in this environment — read its dedicated section below
before trusting any of it in a real deployment.**

## Could not be executed in this development environment

This repository was authored on macOS, in a sandbox without `podman`,
`docker`, a Qt6/KDE Frameworks toolchain, `qmllint`, PAM, polkit,
fapolicyd, or KVM. As a direct result, **none of the following were
actually run**:

- Compiling any of the 7 Qt6/QML apps or 4 D-Bus services (42 `.qml`
  files, 26 `.cpp` files). Written carefully against known-correct
  Qt6/QtDBus/QtSql APIs, reviewed by hand for consistency, but not
  compiled. **Run `cmake --build` on a Linux box with Qt6 before
  trusting any of it compiles.**
- The BlueBuild container image build, PAM/authselect changes,
  fapolicyd rule compilation, D-Bus/polkit policy loading, or the SDDM
  theme rendering.
- Generating an ISO or booting one in a VM — so **every** interaction
  in `tests/checklist_manual_qa.md`, including the entire Parent/Child
  login flow, has been reviewed by reading code, not by seeing it run.

## Milestone 3: the security-critical unverified surface

This is the honest core of this document. Every mechanism below was
designed to be *real* — no hard-coded bypass passwords, no fake UI-only
restrictions, no hidden privilege escalation (see
`docs/SECURITY_ARCHITECTURE.md` for the design) — but "designed to be
real" and "verified to work" are different claims, and only the first
one is true right now.

1. **The D-Bus services have never been started.** `kidsos-auth`,
   `kidsos-policy`, `kidsos-installer`, `kidsos-file-guard` — none have
   run against a real system bus, real polkit, or real `useradd`/
   `chpasswd`. `core/services/common/PolkitCheck.cpp`'s manual D-Bus
   marshaling of the polkit `Subject` struct (a `QDBusArgument`
   `(sa{sv})`) is the single piece of code in this repository I'd flag
   as *most* likely to have a subtle bug — get this wrong and every
   `auth_admin` check silently fails closed (safe) or, worse, the call
   itself errors in a way that a caller mis-handles as "authorized."
   **Before relying on this, write a standalone test binary that calls
   `PolkitCheck::isAuthorized` against a known polkit action and confirm
   the real password dialog appears and the boolean it returns matches
   what you did.**
2. **The child PIN = real Linux password is a genuine security
   tradeoff, not just an implementation shortcut** — see
   `docs/SECURITY_ARCHITECTURE.md`'s "Authentication" section. A 4-digit
   numeric password has ~13 bits of entropy. `pam_faillock` (via
   `authselect enable-feature with-faillock`) mitigates online
   brute-force through the login screen, but this has not been tested,
   and nothing here prevents a determined attacker with a *lot* of
   physical time at the keyboard once faillock's `unlock_time` elapses
   repeatedly. If this ships for real, seriously consider raising the
   minimum PIN length (`AuthService::CreateChildAccount`'s
   `pinPattern` already accepts 4–8 digits — the onboarding UI could
   default to 6).
3. **fapolicyd rule syntax/placement is unverified** (see
   `docs/TRUST_MODEL.md`'s closing section) — the rule DSL varies across
   fapolicyd versions, and `35-kidsos-children.rules`'s ordering
   relative to fapolicyd's own shipped default rules depends on exactly
   what's in the base Kinoite image. **Test each bypass listed in
   `docs/TRUST_MODEL.md`'s table individually** on a real system before
   trusting the "cannot be bypassed" claim.
4. **The `authselect enable-feature with-faillock` build step is
   best-effort** (`recipes/build-kidsos-apps.sh` logs a warning and
   continues on failure rather than failing the whole build) — if the
   base Kinoite image ships a non-default authselect profile, this could
   silently not apply.
5. **The `kidsos-setup` bare-app-as-X11-session technique is unverified**
   — `recipes/files/usr/share/xsessions/kidsos-setup.desktop` execs
   `kidsos-onboarding` directly with no window manager. This is a known
   kiosk pattern but hasn't been confirmed to render/exit cleanly with
   SDDM specifically. If `Finish.qml`'s `Qt.quit()` doesn't cleanly end
   the X session, the greeter may not reappear as `docs/ACCOUNTS_AND_LOGIN.md`
   describes.
6. **The SDDM QML theme has never rendered.** `branding/sddm-theme/kidsos/Main.qml`
   is written against SDDM's documented QML greeter API (`sddm`,
   `userModel`, `sessionModel`), but SDDM's exact model role names and
   the `GreeterEnvironment=` config key's behavior across SDDM versions
   are the kind of thing that's easy to get subtly wrong without a
   greeter to test against.
7. **`fapolicyd-cli --update` and `fagenrules --load` are the exact
   subcommands I'm least confident in** (`FileGuardService.cpp`,
   `build-kidsos-apps.sh`) — verify against `man fapolicyd-cli` /
   `man fapolicyd.rules` for the version actually installed.
8. **The polkit action `.policy` files' `auth_admin` vs `auth_self`
   distinction was applied deliberately** (approvals always re-prompt;
   they never mean "any authenticated user, even the child, can
   approve") — worth an explicit read-through of
   `core/configuration/polkit/actions/*.policy` before trusting it,
   since a flipped `allow_active` value here would be a real privilege
   bug, not a cosmetic one.

None of this is a substitute for a real security review on a running
system before this ships to an actual child's computer.

## What *was* validated here

- `tests/validate_recipe.py`, `tests/validate_locales.py` (180 keys,
  identical across en/he/ar), `tests/validate_brand_colors.py` — all
  pass.
- Brace/paren balance across all 42 `.qml` files; `.desktop`/`.service`
  files parse as valid INI with the required keys; every `qmldir` entry
  has a matching file on disk; every static (non-dynamically-concatenated)
  `LocalizationManager.tr()` key resolves against `en.json`.
- Manual review of every `.qml`/`.cpp`/`.h`/`.sh`/`.yml` file for
  internal consistency (D-Bus interface names matching between service
  and client, polkit action IDs matching between `.policy` files and
  `PolkitCheck::isAuthorized()` call sites, systemd `BusName=` matching
  each service's `registerService()` call, file paths agreeing between
  `docs/SECURITY_ARCHITECTURE.md` and the actual code).

## Deliberately scoped-down decisions (all milestones)

- **KWin/Aurorae window-decoration theming was not attempted** — the
  native title bar stays Kinoite's default Breeze.
- **Plasma "kiosk mode" still not attempted** for the Child session.
- **Quick Settings' Wi-Fi/Bluetooth/Night Light are local UI state**,
  not wired to NetworkManager/BlueZ/night-color.
- **9 of 13 Settings categories are structural placeholders.**
- **`Theme.systemPrefersDark`** isn't wired to a real Plasma
  color-scheme read.
- **Reduced motion is manual**, not auto-detected from the system.
- **Kids Files is a branded front door, not a file manager.**
- **No `.ts`/Qt Linguist localization pipeline** — JSON-based instead.
- **Font files are not vendored** — fetched at image-build time.
- **Kids Store has one demo app**, not a real catalog (spec §15 asked
  only for "the backend request flow," which is fully implemented).

## If you pick this up next

1. Compile everything on a Linux box (`docs/BUILD.md` §2) — fastest way
   to surface mistakes.
2. Get the 4 D-Bus services running standalone (not even in the full
   image yet) and exercise `docs/SECURITY_ARCHITECTURE.md`'s contract
   method by method with `dbus-send`/`busctl` before wiring up the GUIs.
3. Then, and only then, attempt a full image build and VM boot.

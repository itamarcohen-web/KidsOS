# Manual QA checklist (run in a booted VM)

Do this after following `docs/BUILD.md` end to end. Check off each item;
note any failure with enough detail to file a bug.

## Boot & first-boot setup

- [ ] ISO boots to the Fedora Kinoite installer; install completes.
- [ ] After first reboot, the system autologs into `kidsos-setup` and
      goes straight to KidsOS onboarding (not a KDE desktop, no
      password prompt).
- [ ] Onboarding now asks for the **Parent account** (name, username,
      password, confirm) before the child profile — spec §2.
- [ ] After onboarding finishes, the system does **not** re-autologin
      into `kidsos-setup` — `/etc/sddm.conf.d/kidsos-setup-autologin.conf`
      should be gone (`AuthService::MarkFirstBootComplete`), and the
      KidsOS login screen (not a desktop) appears.

## Onboarding — English

- [ ] Welcome screen: KIDS logo animates in, each letter a different
      color, subtitle text correct, "Get started" button obvious.
- [ ] Language screen: three cards, English/עברית/العربية all legible in
      their native script.
- [ ] Name screen: typing updates the "Hi, {name}!" preview live.
- [ ] Avatar screen: all 10 avatars visible, selecting one shows a clear
      selected state.
- [ ] Age screen: tapping an age selects it; Next enables only after a
      selection.
- [ ] Parent connection: QR placeholder + pairing code render; tapping
      the QR simulates a connection within ~1s; "Set this up later" also
      advances.
- [ ] Child PIN: enter 4 digits, confirm 4 digits; mismatched confirm
      shakes and resets; matching pair advances.
- [ ] Finish screen: confetti plays, "Enter KIDS" transitions to the
      desktop.
- [ ] Desktop shows a time-of-day greeting ("Good morning/afternoon/
      evening, {name}") matching the current clock.

## Onboarding — Hebrew / Arabic

- [ ] Selecting עברית or العربية on the Language screen **immediately**
      mirrors the entire layout (back button moves to the right edge,
      progress dots reverse order, footer buttons re-align).
- [ ] All onboarding strings are localized (no leftover English/raw keys
      like `onboarding.name.title` showing literally).
- [ ] The KIDS logo still reads K-I-D-S left-to-right (not mirrored).
- [ ] Repeat the full flow (Welcome → Finish) in each language.

## RTL desktop

- [ ] After onboarding in Hebrew or Arabic, the greeting, frequently-used
      row, dock, launcher, search overlay, notification panel (opens
      from the correct mirrored edge) and quick settings panel are all
      mirrored correctly, not just right-aligned text.
- [ ] Toggle switches in Quick Settings / Accessibility slide to the
      correct (mirrored) side when turned on.

## Keyboard-only navigation

- [ ] Complete the entire onboarding flow using only Tab/Shift+Tab,
      Enter/Space, and Escape (no mouse/touch) — including selecting a
      language, name entry, avatar, age, and PIN digits (physical number
      keys, per `docs/ONBOARDING_FLOW.md`).
- [ ] On the desktop, Tab through the dock, open the launcher/search/
      notifications/quick settings with keyboard alone, and Escape
      closes each overlay.
- [ ] Every focused control shows a visible focus ring.

## Desktop home

- [ ] Large KIDS wordmark appears once, centered, as the central
      branding moment; compact mark appears in the top bar / Settings
      sidebar — not the full wordmark repeated everywhere.
- [ ] "Frequently used" row shows the expected 6 apps.
- [ ] Dock: Apps/Search/pinned apps/notifications bell (with unread
      badge)/status cluster all present, rounded, translucent, with
      visible hover and focus states.

## Launcher

- [ ] Opens full-screen with a fade+scale animation.
- [ ] Search field filters live across all categories.
- [ ] "Recently used" row appears after launching a couple of apps and
      updates order (most recent first).
- [ ] All 8 category tabs (All/Games/School/Creativity/Internet/Music/
      Video/Tools) filter the grid correctly.
- [ ] Closing (✕ button, click-outside, or Escape) animates out cleanly.

## Search

- [ ] Searching "Wi-Fi"-equivalent settings terms (e.g. "Internet")
      surfaces the matching Settings category.
- [ ] Searching "calculator" surfaces Calculator.
- [ ] No-match query shows the friendly empty state, not a blank list.
- [ ] Enter activates the top result.

## Notifications

- [ ] Bell badge shows the correct unread count (2 of the 3 mock
      notifications start unread).
- [ ] Notifications are grouped (System / Family) with group headers.
- [ ] Dismissing one notification removes only that one; "Clear all"
      empties the list and shows the empty state.
- [ ] Panel slides in from the correct (mirrored in RTL) edge.

## Quick settings

- [ ] Opens from tapping the status cluster (dock or top bar).
- [ ] Dark Mode toggle **actually** re-themes every open KidsOS window
      live (not just the panel itself).
- [ ] Wi-Fi/Bluetooth/Night Light toggles animate and hold state while
      the panel is open (real backend wiring is out of scope — see
      `docs/ROADMAP.md`).
- [ ] Volume slider drags smoothly and shows the live percentage.

## Settings

- [ ] Sidebar lists all 13 categories with plain-language names (no
      Linux jargon).
- [ ] Appearance: Light/Dark/Match system cards select correctly and
      Dark actually changes the app's own theme.
- [ ] Language: switching here also changes this window's own layout
      direction immediately.
- [ ] Accessibility: "Reduce motion" toggle visibly reduces animation
      when re-opening the Launcher/Search/Notifications/Quick Settings
      overlays afterward.
- [ ] The 9 remaining categories show the shared placeholder pattern
      (icon + title), not a blank or broken pane.
- [ ] About KidsOS shows the KIDS wordmark, version, and tagline.

## Dark mode

- [ ] Toggle Dark Mode (Quick Settings or Settings → Appearance) and
      confirm every open KidsOS window (desktop, launcher overlay,
      search, notifications, settings, Kids Files) re-themes together.
- [ ] Dark palette is a deliberately different set of colors (see
      `docs/DESIGN_SYSTEM.md`), not the light palette simply inverted —
      spot-check that surfaces/borders/text still have comfortable
      contrast, not blown-out white-on-black.
- [ ] KIDS brand colors are still clearly the same four hues in dark
      mode (brightened, not different colors).

## Kids Files

- [ ] All 8 location cards (Home, School, Documents, Downloads,
      Pictures, Music, Videos, Desktop) are present and correctly
      localized.
- [ ] Clicking each opens Dolphin at the right path; "School" creates
      `~/School` on first use if it doesn't exist yet.

## Default apps

- [ ] Real apps launch: Kids Files (Dolphin), Kids Writer (Kate),
      Calculator (kcalc), Screenshot (Spectacle), Photos (Gwenview),
      Music (Elisa), Video (Haruna), Kids Browser (Firefox via Flatpak),
      Settings.
- [ ] Placeholder tiles (Kids Store, Games, School, Help, KidsOS
      Updates) show the "coming soon" dialog instead of erroring.

## Icons & branding

- [ ] Every default app icon uses the light-gray rounded-square
      container with a colored accent bar (`branding/icons/README.md`)
      — no mismatched icon styles.
- [ ] KIDS logo renders correctly and stays legible at both the large
      (desktop/About) and compact (top bar/sidebar) sizes, with visible
      per-letter rotation at the large size.

## Family accounts & permissions (milestone 3, spec §37)

The 20 items the spec explicitly asks for testing, in order:

1. [ ] **Parent account creation** — onboarding's Parent Account +
   Parent Password screens create a real Linux user (`id <parentuser>`
   succeeds, shows `wheel` in groups).
2. [ ] **Child account creation** — same, no `wheel`, shows
   `kidsos-children`.
3. [ ] **Parent authentication** — the KidsOS login screen's Parent card
   accepts the real password set during onboarding and rejects a wrong
   one with the friendly "That password doesn't look right" message.
4. [ ] **Child authentication** — same for the Child card + PIN, "That
   PIN doesn't look right" on failure.
5. [ ] **Child has no sudo** — as the child, `sudo -l` / any `sudo`
   command fails; `groups` doesn't list `wheel`.
6. [ ] **Parent has administrative privileges** — as the parent, `sudo
   whoami` succeeds (after a password prompt).
7. [ ] **Child cannot modify system-wide KidsOS policy** — as the
   child, `cat /etc/kidsos/policy.json` fails (permission denied) and
   there is no write access.
8. [ ] **Child cannot directly install external package files** —
   download a `.rpm`, double-click it: KidsOS's approval dialog appears
   instead of a package-manager install; `sudo dnf install ./foo.rpm`
   as the child fails at the `sudo` step already (see #5).
9. [ ] **Child cannot directly execute untrusted AppImage** — download
   an AppImage, `chmod +x` it in a terminal, run it directly
   (`./foo.AppImage`, bypassing the GUI dialog entirely) — fapolicyd
   should still block the exec. This is the single most important test
   in this checklist; see `docs/TRUST_MODEL.md`.
10. [ ] **External install request is created** — after the "Ask
    parent" dialog, `kidsos-approvals` (as Parent) shows it under
    Pending.
11. [ ] **Parent can approve request** — clicking Approve prompts for
    the Parent password (polkit) every time, then the app can run.
12. [ ] **Parent can deny request** — clicking Deny requires the same
    prompt; the child's attempt to run it afterward still fails.
13. [ ] **Approved file hash is enforced** — after approval, confirm
    `/etc/fapolicyd/trust.d/kidsos-approved.trust` contains the file's
    exact SHA-256 (`sha256sum` the file and compare).
14. [ ] **Modified file invalidates approval** — after approval, `echo
    x >> approved-file.AppImage` (or any content change), then try to
    run it again: it should be blocked (new hash ≠ trusted hash), and a
    re-approval attempt on the *original* request should fail (see
    `tests/validate_trust_model_invariants.py` for the code-level
    guarantee this exercises).
15. [ ] **Parent can revoke trust** — in `kidsos-approvals`' Trusted
    Apps tab, Revoke removes the entry and the file stops running.
16. [ ] **English login** — full picker → credentials → desktop flow.
17. [ ] **Hebrew login** — same, RTL.
18. [ ] **Arabic login** — same, RTL.
19. [ ] **RTL authentication UI** — card picker, back button, PIN pad,
    and the polkit password dialog itself (a KDE system component, not
    ours — confirm it also respects the system language) all mirror
    correctly.
20. [ ] **Switching users** — from the child desktop, Dock's switch-user
    button returns to the login screen (current session stays running
    in the background); selecting Parent there requires the real
    password again, no shortcut.

## End-to-end VM flow (spec §38)

Power on → KIDS login screen → select Parent → enter Parent password →
Parent desktop (normal Plasma + small "Parent Mode" badge, top corner)
→ log out / switch user → select Child → enter Child PIN → Child
desktop → download an external executable → attempt to run it → KidsOS
blocks it (fapolicyd) → "Parent approval required" dialog → request
parent approval → switch to Parent → approve in `kidsos-approvals` →
return to Child → execute the now-approved application → verify that
modifying the file afterward invalidates the approval (item 14 above).

## Regression pass

- [ ] Switching language in `kidsos-settings` after setup updates the
      Settings UI immediately, and the launcher picks up the same
      language on next open.
- [ ] Reduced motion, once enabled, persists across re-opening apps
      within the same session (it's a runtime toggle, not yet persisted
      to disk — see `docs/ROADMAP.md`, this is expected for now).

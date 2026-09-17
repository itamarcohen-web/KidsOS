# Manual QA checklist (run in a booted VM)

Do this after following `docs/BUILD.md` end to end. Check off each item;
note any failure with enough detail to file a bug.

## Boot & first-boot account

- [ ] ISO boots to the Fedora Kinoite installer; install completes.
- [ ] After first reboot, the system logs in without a password prompt
      and goes straight to KidsOS onboarding (not a KDE desktop).
- [ ] `id kid` (via a TTY/SSH as another user, or `journalctl` review)
      shows **no** `wheel` group membership.
- [ ] `/var/lib/kidsos/firstboot-done` exists after first boot.

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

## Regression pass

- [ ] Switching language in `kidsos-settings` after setup updates the
      Settings UI immediately, and the launcher picks up the same
      language on next open.
- [ ] Reduced motion, once enabled, persists across re-opening apps
      within the same session (it's a runtime toggle, not yet persisted
      to disk — see `docs/ROADMAP.md`, this is expected for now).

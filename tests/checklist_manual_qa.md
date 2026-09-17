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
- [ ] Desktop shows "Hello, {name}" with the name typed earlier.

## Onboarding — Hebrew

- [ ] Selecting עברית on the Language screen **immediately** mirrors the
      entire layout (back button moves to the right edge, progress dots
      reverse order, footer buttons re-align).
- [ ] All onboarding strings are in Hebrew (no leftover English/keys
      like `onboarding.name.title` showing literally).
- [ ] The KIDS logo still reads K-I-D-S left-to-right (not mirrored).
- [ ] Repeat the full flow (Welcome → Finish) in Hebrew.

## Onboarding — Arabic

- [ ] Same as the Hebrew checklist, in Arabic.

## RTL desktop

- [ ] After onboarding in Hebrew or Arabic, the desktop's greeting, app
      grid, search bar and bottom nav are all mirrored correctly, not
      just right-aligned text.

## Keyboard-only navigation

- [ ] Complete the entire onboarding flow using only Tab/Shift+Tab,
      Enter/Space, and Escape (no mouse/touch) — including selecting a
      language, name entry, avatar, age, and PIN digits (physical number
      keys, per `docs/ONBOARDING_FLOW.md`).
- [ ] Every focused control shows a visible focus ring.

## Desktop

- [ ] All 14 app tiles are present and correctly labeled/localized.
- [ ] Real apps launch: Files (Dolphin), Text Editor (Kate), Calculator
      (kcalc), Screenshot (Spectacle), Photos (Gwenview), Music (Elisa),
      Video (Haruna), Browser (Firefox via Flatpak), Settings.
- [ ] Placeholder tiles (Kids Store, Games, School, Help, KidsOS
      Updates) show the "coming soon" dialog instead of erroring.
- [ ] Search filters the app grid live.
- [ ] Notifications panel opens/closes and shows the empty state.
- [ ] Clock updates every minute; Wi-Fi indicator tooltip shows.

## Regression pass

- [ ] Switching language in `kidsos-settings` after setup updates the
      Settings UI immediately.
- [ ] Reduced-motion: enabling "reduce animations" in system
      accessibility settings measurably reduces/removes onboarding
      entrance animations (see `docs/KNOWN_LIMITATIONS.md` — this hook
      exists in `Theme.qml` but nothing wires it to the real
      accessibility setting yet; expect this to currently **fail** and
      file it against `docs/ROADMAP.md`).

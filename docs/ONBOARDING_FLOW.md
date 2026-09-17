# Onboarding flow

`apps/onboarding/qml/Main.qml` drives eight screens
(`apps/onboarding/qml/screens/`) through a `StackView`, sharing one
mutable `appState` object (name, avatarId, age, pin draft, language)
passed into each pushed screen as a required property — no global
singleton, no cross-screen coupling beyond that one object.

| # | Screen | File | Key interaction |
|---|---|---|---|
| 1 | Welcome | `Welcome.qml` | Animated KIDS wordmark entrance, single CTA |
| 2 | Language | `Language.qml` | 3 cards; selecting one flips `LayoutMirroring` live |
| 3 | Name | `Name.qml` | Large text field + animated "Hi, {name}!" preview |
| 4 | Avatar | `Avatar.qml` | 10-avatar grid, tap to select |
| 5 | Age | `Age.qml` | Large numeric buttons, 5–16 |
| 6 | Parent connection | `ParentConnect.qml` | **Placeholder** — mock QR + pairing code, tap-to-simulate connect |
| 7 | Child PIN | `PinSetup.qml` | 4-digit create + confirm, numeric keypad, salted-hash storage |
| 8 | Finish | `Finish.qml` | Confetti, writes profile + completion flag, hands off to the desktop |

Screens 2–8 are `OnboardingPage { … }` instances (see
`docs/DESIGN_SYSTEM.md`), giving every step the same back button, step
dots, and footer button placement.

## What's real vs. mocked in this milestone

- **Real:** name/avatar/age capture, language switching + RTL, PIN
  creation with salted SHA-256 hashing (`ProfileBridge::setChildPin`),
  profile persistence, the completion flag that gates the next session
  start.
- **Placeholder (explicitly, per product scope):** parent pairing has no
  real networking — tapping the QR box just plays a 900ms "connecting"
  animation and flips to a mocked "connected" state. See
  `docs/ROADMAP.md` for the real Parent Cloud pairing protocol this will
  be replaced by.

## Keyboard navigation

`OnboardingPage` wires `Escape` → back, `Return`/`Enter` → primary
action, and every interactive control (`KidsButton`, text field,
language/avatar/age tiles) is a real focusable item with a visible focus
ring (`KidsButton`'s `visualFocus` outline) — a child should be able to
complete setup with a keyboard alone, not just a mouse/touchscreen.

# Onboarding flow

`apps/onboarding/qml/Main.qml` drives ten screens
(`apps/onboarding/qml/screens/`) through a `StackView`, sharing one
mutable `appState` object (parent name/username, child name/username/
avatarId/age, language) passed into each pushed screen as a required
property — no global singleton, no cross-screen coupling beyond that one
object. See `docs/ACCOUNTS_AND_LOGIN.md` for the surrounding
kidsos-setup session this app runs in during first boot.

| # | Screen | File | Key interaction |
|---|---|---|---|
| 1 | Welcome | `Welcome.qml` | Animated KIDS wordmark entrance, single CTA |
| 2 | Language | `Language.qml` | 3 cards; selecting one flips `LayoutMirroring` live |
| 3 | Parent account | `ParentAccount.qml` | Display name + username (auto-suggested, editable) |
| 4 | Parent password | `ParentPassword.qml` | Password + confirm → `kidsos-auth::CreateParentAccount` over D-Bus |
| 5 | Child name | `Name.qml` | Name + username field, animated "Hi, {name}!" preview |
| 6 | Avatar | `Avatar.qml` | 10-avatar grid, tap to select |
| 7 | Age | `Age.qml` | Large numeric buttons, 5–16 |
| 8 | Child PIN | `PinSetup.qml` | 4-digit create + confirm → `kidsos-auth::CreateChildAccount` over D-Bus |
| 9 | Parent connection | `ParentConnect.qml` | **Placeholder** — mock QR + pairing code, tap-to-simulate connect |
| 10 | Finish | `Finish.qml` | Confetti, marks first boot complete, ends the setup session |

Screens 2, 4–10 are `OnboardingPage { … }` instances (see
`docs/DESIGN_SYSTEM.md`), giving every step the same back button, step
dots, and footer button placement.

## What's real vs. mocked in this milestone

- **Real:** both accounts are genuine Linux users created via
  `OnboardingBridge` → D-Bus → `kidsos-auth` → `useradd`/`chpasswd` (see
  `docs/SECURITY_ARCHITECTURE.md`). The Parent's password and the
  Child's PIN are both real Linux login credentials, hashed by the
  system's own shadow/crypt mechanism — nothing is stored by KidsOS
  itself. Language switching + RTL, avatar/age capture, and the
  step-by-step UX are all real and unchanged from milestone 1/2's
  polish level.
- **Placeholder (explicitly, per product scope):** parent pairing has no
  real networking — tapping the QR box just plays a 900ms "connecting"
  animation and flips to a mocked "connected" state. See
  `docs/ROADMAP.md` for the real Parent Cloud pairing protocol this will
  be replaced by.

## Keyboard navigation

`OnboardingPage` wires `Escape` → back, `Return`/`Enter` → primary
action, and every interactive control (`KidsButton`, text field,
language/avatar/age tiles) is a real focusable item with a visible focus
ring (`KidsButton`'s `visualFocus` outline) — a parent or child should be
able to complete setup with a keyboard alone, not just a mouse/touchscreen.

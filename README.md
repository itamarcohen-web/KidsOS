# KidsOS

Created by **Itamar Cohen**.

A colorful, friendly operating system for kids and teens (ages ~8–16),
built on **Fedora Kinoite**, **KDE Plasma**, **BlueBuild** and
**Flatpak**. Milestone 1 built the OS foundation (onboarding, branding,
localization); milestone 2 built the complete child desktop experience
(home screen, launcher, dock, search, notifications, quick settings,
dark mode, Settings); milestone 3 builds the **family account and
permission system** — a real Parent (administrator) and Child (standard
user) account, a polished login screen, and Linux-enforced (not just
UI-hidden) app-approval and external-file-trust workflows; milestone 4
builds the **Local Safety AI System** (`docs/SAFETY_AI.md`) — fully
local OCR + text/vision safety classification of periodic screen
samples, with zero cloud AI dependency.

<p>
  <strong style="color:#FF5A5F">K</strong><strong style="color:#FFB400">I</strong><strong style="color:#00C2A8">D</strong><strong style="color:#3D8BFD">S</strong>
</p>

## Repository layout

```
recipes/            recipe.yml (points into files/ — see docs/BUILD.md for why
                     everything below lives under files/, a BlueBuild requirement)
files/
  system/            Rootfs overlay: systemd units, .desktop/autostart, SDDM/xsession
                      config, polkit actions, D-Bus policy, fapolicyd rules,
                      /usr/lib/kidsos/models/ (Safety AI model manifests)
  branding/          Logo, icons, wallpaper, design-system tokens (Theme.qml),
                     Plasma color scheme, SDDM login theme
  apps/
    common/             Shared QML component library (KidsOS.Common) — onboarding UI,
                         desktop shell, and the login screen all import this
    onboarding/         First-boot setup wizard (Qt6/QML, 10 screens: Parent account
                         + password, then Child profile + PIN)
    launcher/           The KidsOS desktop (see docs/DESKTOP_SHELL.md)
    settings/           13-category Settings app, incl. "managed by parent" banners
    files/              Kids Files — branded location-card front door onto Dolphin
    approvals/          Parent Approval app — approve/deny requests, revoke trust
    parent-indicator/   Small "Parent Mode" badge + Switch User, for the Parent session
    file-guard-prompt/  "Parent approval required" dialog for untrusted downloads
    safety-agent/       Local Safety AI's Child-session agent — capture/OCR/AI
                         pipeline (see docs/SAFETY_AI.md)
  core/
    localization/       KidsOS.Localization runtime + en/he/ar string tables (196 keys)
    services/           kidsos-auth, kidsos-policy, kidsos-installer, kidsos-file-guard,
                         kidsos-safety — the five privileged D-Bus services (see
                         docs/SECURITY_ARCHITECTURE.md)
docs/                 Architecture, security architecture, trust model, accounts &
                       login, design system, desktop shell, localization, build & QA,
                       Safety AI
tests/                Static validation scripts + manual QA checklist
THIRD_PARTY_NOTICES.md  Model licensing/provenance review log (Safety AI)
```

Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), then
[`docs/SECURITY_ARCHITECTURE.md`](docs/SECURITY_ARCHITECTURE.md) for
exactly which Linux groups/services/policies enforce the Parent/Child
boundary, and [`docs/TRUST_MODEL.md`](docs/TRUST_MODEL.md) for how
external-app blocking actually resists bypass attempts.

## Status

This is a from-scratch, unreleased project. It was authored without
access to a container runtime, Qt toolchain, PAM/polkit/fapolicyd, or
VM/KVM in the development environment, so **the image has not been
built or booted yet**. Milestone 3 in particular introduces the most
security-critical, least-verifiable-here code in the repository — see
[`docs/KNOWN_LIMITATIONS.md`](docs/KNOWN_LIMITATIONS.md)'s dedicated
section before trusting any of it in a real deployment, and
[`docs/BUILD.md`](docs/BUILD.md) for the exact commands to build, boot
and test it on a Linux host or in CI.

Explicitly out of scope so far (placeholders only): a real Kids Store
catalog (one demo app exercises the full request/approval backend),
Parent Cloud pairing, Screen Time, Safety AI, Web Protection, and 9 of
13 Settings categories — see [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Quick links

- [Security architecture](docs/SECURITY_ARCHITECTURE.md) — groups, PAM, D-Bus services, polkit actions
- [Trust model](docs/TRUST_MODEL.md) — how external-app blocking resists bypass
- [Accounts & login](docs/ACCOUNTS_AND_LOGIN.md) — onboarding flow, SDDM theme, switching users
- [Design system](docs/DESIGN_SYSTEM.md) — colors, type, spacing, motion, dark mode
- [Desktop shell](docs/DESKTOP_SHELL.md) — dock, launcher, search, notifications, quick settings
- [Localization](docs/LOCALIZATION.md) — how RTL and string loading work
- [Onboarding flow](docs/ONBOARDING_FLOW.md) — the 10-screen wizard
- [Build & boot](docs/BUILD.md)
- [Manual QA checklist](tests/checklist_manual_qa.md)

## License

Not yet specified.
# KidsOS
# KidsOS

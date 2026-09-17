# KidsOS

A colorful, friendly operating system for kids and teens (ages ~8–16),
built on **Fedora Kinoite**, **KDE Plasma**, **BlueBuild** and
**Flatpak**. This repository is the first working foundation: a
full-screen first-boot onboarding experience, a KidsOS desktop/launcher,
a non-admin child account, and English/Hebrew/Arabic localization with
first-class RTL — all built from scratch, not a reskinned KDE session.

<p>
  <strong style="color:#FF5A5F">K</strong><strong style="color:#FFB400">I</strong><strong style="color:#00C2A8">D</strong><strong style="color:#3D8BFD">S</strong>
</p>

## Repository layout

```
recipes/            BlueBuild recipe.yml + system files (systemd, .desktop, autostart)
branding/            Logo, icons, wallpaper, design-system tokens (Theme.qml), Plasma color scheme
apps/
  common/             Shared QML component library (KidsOS.Common)
  onboarding/         First-boot setup wizard (Qt6/QML, 8 screens)
  launcher/           The KidsOS desktop/home screen
  settings/           Placeholder settings shell
core/
  localization/       KidsOS.Localization runtime + en/he/ar string tables
  configuration/      Child account creation script, polkit restrictions
docs/                 Architecture, design system, localization, build & QA docs
tests/                Static validation scripts + manual QA checklist
```

Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for how the
pieces fit together.

## Status

This is a from-scratch, unreleased milestone. It was authored without
access to a container runtime, Qt toolchain, or VM/KVM in the
development environment, so **the image has not been built or booted
yet** — see [`docs/KNOWN_LIMITATIONS.md`](docs/KNOWN_LIMITATIONS.md) for
exactly what was and wasn't verified, and
[`docs/BUILD.md`](docs/BUILD.md) for the exact commands to build, boot
and test it on a Linux host or in CI.

Explicitly out of scope for this milestone (placeholders only): Kids
Store, real Parent Cloud pairing, Parent Controls, Screen Time, Safety
AI, Web Protection — see [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Quick links

- [Design system](docs/DESIGN_SYSTEM.md) — colors, type, spacing, motion
- [Localization](docs/LOCALIZATION.md) — how RTL and string loading work
- [Onboarding flow](docs/ONBOARDING_FLOW.md) — the 8-screen wizard
- [Build & boot](docs/BUILD.md)
- [Manual QA checklist](tests/checklist_manual_qa.md)

## License

Not yet specified.

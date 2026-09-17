# KidsOS

A colorful, friendly operating system for kids and teens (ages ~8–16),
built on **Fedora Kinoite**, **KDE Plasma**, **BlueBuild** and
**Flatpak**. Milestone 1 built the OS foundation (onboarding, non-admin
child account, branding, localization); milestone 2 builds the complete
**child desktop experience** — a modern home screen, launcher, dock,
system-wide search, notification center, quick settings, dark mode, and
a 13-category Settings app — all built from scratch, not a reskinned KDE
session.

<p>
  <strong style="color:#FF5A5F">K</strong><strong style="color:#FFB400">I</strong><strong style="color:#00C2A8">D</strong><strong style="color:#3D8BFD">S</strong>
</p>

## Repository layout

```
recipes/            BlueBuild recipe.yml + system files (systemd, .desktop, autostart)
branding/            Logo, icons, wallpaper, design-system tokens (Theme.qml), Plasma color scheme
apps/
  common/             Shared QML component library (KidsOS.Common) — onboarding UI +
                       desktop shell: Dock, LauncherOverlay, SearchOverlay,
                       NotificationCenter, QuickSettingsPanel, AppTile, ToggleRow
  onboarding/         First-boot setup wizard (Qt6/QML, 8 screens)
  launcher/           The KidsOS desktop: home screen, dock, launcher, search,
                       notifications, quick settings (see docs/DESKTOP_SHELL.md)
  settings/           13-category Settings app (Appearance/Language/Accessibility
                       functional, rest structured placeholders)
  files/              Kids Files — branded location-card front door onto Dolphin
core/
  localization/       KidsOS.Localization runtime + en/he/ar string tables (136 keys)
  configuration/      Child account creation script, polkit restrictions
docs/                 Architecture, design system, desktop shell, localization,
                       onboarding flow, build & QA docs
tests/                Static validation scripts + manual QA checklist
```

Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for how the
pieces fit together, then [`docs/DESKTOP_SHELL.md`](docs/DESKTOP_SHELL.md)
for the desktop specifically.

## Status

This is a from-scratch, unreleased project. It was authored without
access to a container runtime, Qt toolchain, or VM/KVM in the
development environment, so **the image has not been built or booted
yet** — see [`docs/KNOWN_LIMITATIONS.md`](docs/KNOWN_LIMITATIONS.md) for
exactly what was and wasn't verified, and
[`docs/BUILD.md`](docs/BUILD.md) for the exact commands to build, boot
and test it on a Linux host or in CI.

Explicitly out of scope so far (placeholders only): Kids Store, real
Parent Cloud pairing, Parent Controls, Screen Time, Safety AI, Web
Protection, and 9 of 13 Settings categories — see
[`docs/ROADMAP.md`](docs/ROADMAP.md).

## Quick links

- [Design system](docs/DESIGN_SYSTEM.md) — colors, type, spacing, motion, dark mode
- [Desktop shell](docs/DESKTOP_SHELL.md) — dock, launcher, search, notifications, quick settings
- [Localization](docs/LOCALIZATION.md) — how RTL and string loading work
- [Onboarding flow](docs/ONBOARDING_FLOW.md) — the 8-screen wizard
- [Build & boot](docs/BUILD.md)
- [Manual QA checklist](tests/checklist_manual_qa.md)

## License

Not yet specified.

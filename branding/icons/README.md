# KidsOS app icon system

Every default app icon shares one template:

- **Background:** light gray rounded square, `#E8E8E8`, corner radius
  `32px` on a `128px` canvas (`Theme.iconRadiusRatio` in
  `branding/themes/qml/Theme.qml` encodes this ratio for anywhere icons
  get drawn at a different size).
- **Center glyph:** one simple, high-contrast symbol — no detailed
  illustration.
- **Accent bar:** a short rounded bar in one of the four KIDS brand
  colors along the bottom edge, tying every icon back to the brand
  palette without repainting the whole tile in that color.

This keeps the icon grid visually calm and consistent (all the same
neutral gray) while still reading as colorful and brand-consistent
through the accent bar and glyph color — "strong colors, clean
composition," not a wall of saturated tiles.

| File | App | Accent |
|---|---|---|
| `kidsos-browser.svg` | Kids Browser | Sky Blue |
| `kidsos-store.svg` | Kids Store | Coral Red |
| `kidsos-games.svg` | Games | Sunny Amber |
| `kidsos-school.svg` | School | Mint Teal |
| `kidsos-music.svg` | Music | Purple (secondary) |
| `kidsos-files.svg` | Kids Files | Sky Blue |
| `kidsos-calculator.svg` | Calculator | Sunny Amber |
| `kidsos-texteditor.svg` | Kids Writer | Mint Teal |
| `kidsos-screenshot.svg` | Screenshot | Coral Red |
| `kidsos-video.svg` | Video | Pink (secondary) |
| `kidsos-photos.svg` | Photos | Sky Blue |
| `kidsos-settings.svg` | Settings | Mint Teal |
| `kidsos-help.svg` | Help | Sunny Amber |
| `kidsos-updates.svg` | KidsOS Updates | Sky Blue |
| `kidsos-launcher.svg` | KIDS (launcher/taskbar) | — gradient mark, see `../logo/kids-mark.svg` |
| `kidsos-onboarding.svg` | KIDS Setup | — gradient mark |

`apps/common/qml/AppTile.qml` and `Dock.qml` render the same visual
language natively in QML (a tinted rounded-square chip + glyph) for
in-app tiles, so the desktop and the installed `.svg` icons match.

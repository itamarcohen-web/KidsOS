#pragma once

#include <QString>

// spec §14: identifies the foreground application at capture time,
// best-effort. Two implementations share this interface (KWin D-Bus
// scripting on Plasma/Wayland, X11 WM_CLASS fallback) — see
// ActiveApplicationProvider.cpp. Neither is guaranteed to succeed for
// every window (a game running full-screen through Steam's Proton
// layer, for instance, may not expose a clean title), which is exactly
// why capture_quality exists on SafetyEvent (spec §15).
class IActiveApplicationProvider
{
public:
    virtual ~IActiveApplicationProvider() = default;

    struct Result {
        QString applicationName; // empty if it couldn't be resolved
        bool resolved = false;
    };

    virtual Result activeApplication() = 0;

    // Small built-in list of well-known game/chat clients (spec §15's
    // examples: Roblox, Minecraft, Discord, Steam, browser games) used
    // by ContextEngine's de-escalation rule — not exhaustive, and
    // intentionally simple pattern matching rather than a maintained
    // catalog.
    static bool isKnownGame(const QString &applicationName);
};

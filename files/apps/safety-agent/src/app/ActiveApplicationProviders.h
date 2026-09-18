#pragma once

#include "IActiveApplicationProvider.h"

// KWin's D-Bus scripting interface (org.kde.KWin), used on the Plasma
// session KidsOS ships regardless of X11/Wayland underneath — this is
// the primary provider.
class KWinActiveApplicationProvider : public IActiveApplicationProvider
{
public:
    Result activeApplication() override;
};

// Fallback for the rare case KWin's scripting interface isn't
// reachable: reads the focused window's WM_CLASS directly via Xlib.
// Only meaningful on an X11 session.
class X11ActiveApplicationProvider : public IActiveApplicationProvider
{
public:
    Result activeApplication() override;
};

#pragma once

#include <QImage>
#include <QString>

// Screen-capture abstraction (spec §3): the concrete implementation
// must respect the current session's platform security model rather
// than bypass it. Two real implementations exist —
// WaylandPortalCapture (org.freedesktop.portal.Screenshot) and
// X11Capture (QScreen::grabWindow) — chosen at startup by
// SafetyAgent::createCaptureProvider() based on XDG_SESSION_TYPE. See
// docs/SAFETY_AI.md for the portal-permission caveat that's genuinely
// unverifiable without a live KDE Wayland session.
class IScreenCaptureProvider
{
public:
    virtual ~IScreenCaptureProvider() = default;

    // Empty QImage on failure (e.g. portal denied, no active session).
    // Must never block the caller for more than a few seconds and must
    // never itself change window focus or show any UI.
    virtual QImage captureActiveScreen() = 0;

    virtual QString providerName() const = 0;
};

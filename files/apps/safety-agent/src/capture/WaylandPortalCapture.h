#pragma once

#include "IScreenCaptureProvider.h"

// Uses org.freedesktop.portal.Screenshot (the XDG Desktop Portal), the
// platform-supported, permission-model-respecting capture path
// required on Wayland (spec §3) — never a compositor-bypassing
// mechanism. Deliberately the *Screenshot* portal rather than
// ScreenCast+PipeWire: Screenshot is built for exactly this "grab one
// still frame" use case, so there's no video-stream negotiation to
// manage for a sample taken once every 120 seconds.
//
// Whether portal-kde silently reuses a previously granted permission
// for a non-interactive, non-sandboxed automated caller (as opposed to
// re-prompting) is not something that can be confirmed without a live
// KDE Plasma Wayland session — see docs/KNOWN_LIMITATIONS.md.
class WaylandPortalCapture : public IScreenCaptureProvider
{
public:
    QImage captureActiveScreen() override;
    QString providerName() const override { return QStringLiteral("wayland-portal"); }
};

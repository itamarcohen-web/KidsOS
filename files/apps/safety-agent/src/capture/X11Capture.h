#pragma once

#include "IScreenCaptureProvider.h"

// X11 has no portal-equivalent capture restriction, so
// QScreen::grabWindow works directly — used as the fallback session
// type when XDG_SESSION_TYPE isn't "wayland" (see
// docs/KNOWN_LIMITATIONS.md: Kinoite ships both session types by
// default, and this milestone doesn't change that).
class X11Capture : public IScreenCaptureProvider
{
public:
    QImage captureActiveScreen() override;
    QString providerName() const override { return QStringLiteral("x11"); }
};

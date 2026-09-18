#pragma once

#include "IScreenCaptureProvider.h"

#include <QObject>
#include <QVariantMap>

class QEventLoop;

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
//
// Inherits QObject (in addition to the pure-interface
// IScreenCaptureProvider) only because QDBusConnection::connect()
// requires a real QObject slot to receive the portal's
// Request.Response signal — it can't target a lambda or std::function.
class WaylandPortalCapture : public QObject, public IScreenCaptureProvider
{
    Q_OBJECT

public:
    QImage captureActiveScreen() override;
    QString providerName() const override { return QStringLiteral("wayland-portal"); }

private Q_SLOTS:
    void handlePortalResponse(uint response, const QVariantMap &results);

private:
    QString m_resultUri;
    bool m_gotResponse = false;
    QEventLoop *m_loop = nullptr;
};

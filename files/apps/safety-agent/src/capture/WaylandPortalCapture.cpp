#include "WaylandPortalCapture.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QDBusReply>
#include <QDebug>
#include <QEventLoop>
#include <QFile>
#include <QTimer>
#include <QUrl>
#include <QVariantMap>

namespace {
constexpr int kPortalTimeoutMs = 5000;
}

QImage WaylandPortalCapture::captureActiveScreen()
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    QDBusInterface portal(QStringLiteral("org.freedesktop.portal.Desktop"),
                           QStringLiteral("/org/freedesktop/portal/desktop"),
                           QStringLiteral("org.freedesktop.portal.Screenshot"), bus);
    if (!portal.isValid()) {
        qWarning() << "kidsos-safety-agent: XDG portal unavailable:" << bus.lastError().message();
        return {};
    }

    // interactive=false: no cropping/picker UI (spec §33 — no popup).
    // Whether the compositor still surfaces a one-time permission
    // dialog on the very first call is the unverified part noted in
    // WaylandPortalCapture.h.
    QVariantMap options;
    options[QStringLiteral("interactive")] = false;

    const QDBusReply<QDBusObjectPath> reply = portal.call(QStringLiteral("Screenshot"), QString(), options);
    if (!reply.isValid()) {
        qWarning() << "kidsos-safety-agent: Screenshot portal call failed:" << reply.error().message();
        return {};
    }

    QString resultUri;
    bool gotResponse = false;

    QEventLoop loop;
    QTimer timeoutTimer;
    timeoutTimer.setSingleShot(true);
    QObject::connect(&timeoutTimer, &QTimer::timeout, &loop, &QEventLoop::quit);

    const bool connected = bus.connect(
        QString(), reply.value().path(), QStringLiteral("org.freedesktop.portal.Request"),
        QStringLiteral("Response"),
        &loop, [&](uint response, const QVariantMap &results) {
            gotResponse = true;
            if (response == 0)
                resultUri = results.value(QStringLiteral("uri")).toString();
            loop.quit();
        });

    if (!connected) {
        qWarning() << "kidsos-safety-agent: could not subscribe to portal Request.Response";
        return {};
    }

    timeoutTimer.start(kPortalTimeoutMs);
    loop.exec();

    if (!gotResponse || resultUri.isEmpty())
        return {};

    const QString localPath = QUrl(resultUri).toLocalFile();
    QImage image(localPath);
    QFile::remove(localPath); // spec §20: never leave a copy on disk
    return image;
}

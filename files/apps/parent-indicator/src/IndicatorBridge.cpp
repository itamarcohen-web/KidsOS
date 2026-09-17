#include "IndicatorBridge.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>

IndicatorBridge::IndicatorBridge(QObject *parent) : QObject(parent) { }

bool IndicatorBridge::switchUser()
{
    QDBusInterface auth(QStringLiteral("org.kidsos.Auth1"), QStringLiteral("/org/kidsos/Auth1"),
                         QStringLiteral("org.kidsos.Auth1"), QDBusConnection::systemBus());
    if (!auth.isValid())
        return false;
    QDBusReply<bool> reply = auth.call(QStringLiteral("SwitchToGreeter"));
    return reply.isValid() && reply.value();
}

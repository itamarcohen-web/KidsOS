#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusError>
#include <QDebug>

#include "AuthService.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    AuthService service;

    QDBusConnection bus = QDBusConnection::systemBus();
    if (!bus.registerObject(QStringLiteral("/org/kidsos/Auth1"), &service,
                             QDBusConnection::ExportScriptableSlots)) {
        qCritical() << "kidsos-auth: failed to register D-Bus object:" << bus.lastError().message();
        return 1;
    }
    if (!bus.registerService(QStringLiteral("org.kidsos.Auth1"))) {
        qCritical() << "kidsos-auth: failed to register D-Bus service:" << bus.lastError().message();
        return 1;
    }

    return app.exec();
}

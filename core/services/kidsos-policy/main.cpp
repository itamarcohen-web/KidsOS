#include <QCoreApplication>
#include <QDBusConnection>
#include <QDebug>

#include "PolicyService.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    PolicyService service;

    QDBusConnection bus = QDBusConnection::systemBus();
    if (!bus.registerObject(QStringLiteral("/org/kidsos/Policy1"), &service,
                             QDBusConnection::ExportScriptableSlots)) {
        qCritical() << "kidsos-policy: failed to register D-Bus object:" << bus.lastError().message();
        return 1;
    }
    if (!bus.registerService(QStringLiteral("org.kidsos.Policy1"))) {
        qCritical() << "kidsos-policy: failed to register D-Bus service:" << bus.lastError().message();
        return 1;
    }

    return app.exec();
}

#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusError>
#include <QDebug>

#include "SafetyService.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    SafetyService service;
    if (!service.init()) {
        qCritical() << "kidsos-safety: failed to open the events database";
        return 1;
    }

    QDBusConnection bus = QDBusConnection::systemBus();
    if (!bus.registerObject(QStringLiteral("/org/kidsos/Safety1"), &service,
                             QDBusConnection::ExportScriptableSlots)) {
        qCritical() << "kidsos-safety: failed to register D-Bus object:" << bus.lastError().message();
        return 1;
    }
    if (!bus.registerService(QStringLiteral("org.kidsos.Safety1"))) {
        qCritical() << "kidsos-safety: failed to register D-Bus service:" << bus.lastError().message();
        return 1;
    }

    return app.exec();
}

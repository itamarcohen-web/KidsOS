#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusError>
#include <QDebug>

#include "InstallerService.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    InstallerService service;
    if (!service.init()) {
        qCritical() << "kidsos-installer: failed to open request store";
        return 1;
    }

    QDBusConnection bus = QDBusConnection::systemBus();
    if (!bus.registerObject(QStringLiteral("/org/kidsos/Installer1"), &service,
                             QDBusConnection::ExportScriptableSlots)) {
        qCritical() << "kidsos-installer: failed to register D-Bus object:" << bus.lastError().message();
        return 1;
    }
    if (!bus.registerService(QStringLiteral("org.kidsos.Installer1"))) {
        qCritical() << "kidsos-installer: failed to register D-Bus service:" << bus.lastError().message();
        return 1;
    }

    return app.exec();
}

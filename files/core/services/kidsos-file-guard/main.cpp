#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusError>
#include <QDebug>

#include "FileGuardService.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    FileGuardService service;

    QDBusConnection bus = QDBusConnection::systemBus();
    if (!bus.registerObject(QStringLiteral("/org/kidsos/FileGuard1"), &service,
                             QDBusConnection::ExportScriptableSlots)) {
        qCritical() << "kidsos-file-guard: failed to register D-Bus object:" << bus.lastError().message();
        return 1;
    }
    if (!bus.registerService(QStringLiteral("org.kidsos.FileGuard1"))) {
        qCritical() << "kidsos-file-guard: failed to register D-Bus service:" << bus.lastError().message();
        return 1;
    }

    return app.exec();
}

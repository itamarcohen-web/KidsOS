#include "LauncherBridge.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>

namespace {
QString configDir()
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                          + QStringLiteral("/kidsos");
    QDir().mkpath(base);
    return base;
}
}

LauncherBridge::LauncherBridge(QObject *parent) : QObject(parent)
{
    QFile profileFile(configDir() + QStringLiteral("/profile.json"));
    if (profileFile.open(QIODevice::ReadOnly)) {
        const QJsonObject obj = QJsonDocument::fromJson(profileFile.readAll()).object();
        m_profile = obj.toVariantMap();
    }

    QFile settingsFile(configDir() + QStringLiteral("/settings.json"));
    if (settingsFile.open(QIODevice::ReadOnly)) {
        const QJsonObject obj = QJsonDocument::fromJson(settingsFile.readAll()).object();
        const QString mode = obj.value(QStringLiteral("appearanceMode")).toString();
        if (!mode.isEmpty())
            m_appearanceMode = mode;
    }
}

QVariantMap LauncherBridge::profile() const
{
    return m_profile;
}

QString LauncherBridge::appearanceMode() const
{
    return m_appearanceMode;
}

bool LauncherBridge::launchCommand(const QString &command, const QStringList &args)
{
    if (command.isEmpty())
        return false;
    return QProcess::startDetached(command, args);
}

void LauncherBridge::saveAppearanceMode(const QString &mode)
{
    m_appearanceMode = mode;

    QJsonObject settings;
    settings["appearanceMode"] = mode;

    QFile file(configDir() + QStringLiteral("/settings.json"));
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(QJsonDocument(settings).toJson(QJsonDocument::Indented));
        file.close();
    }
}

bool LauncherBridge::switchUser()
{
    QDBusInterface auth(QStringLiteral("org.kidsos.Auth1"), QStringLiteral("/org/kidsos/Auth1"),
                         QStringLiteral("org.kidsos.Auth1"), QDBusConnection::systemBus());
    if (!auth.isValid())
        return false;
    QDBusReply<bool> reply = auth.call(QStringLiteral("SwitchToGreeter"));
    return reply.isValid() && reply.value();
}

QString LauncherBridge::submitInstallRequest(const QString &appId, const QString &appName,
                                              const QStringList &permissions)
{
    QDBusInterface installer(QStringLiteral("org.kidsos.Installer1"),
                              QStringLiteral("/org/kidsos/Installer1"),
                              QStringLiteral("org.kidsos.Installer1"), QDBusConnection::systemBus());
    if (!installer.isValid())
        return QString();

    const QString childId = qEnvironmentVariable("USER");
    QDBusReply<QString> reply = installer.call(QStringLiteral("SubmitInstallRequest"), childId, appId,
                                                appName, QStringLiteral("kids-store"), permissions);
    return reply.isValid() ? reply.value() : QString();
}

QVariantList LauncherBridge::myInstallRequests()
{
    QDBusInterface installer(QStringLiteral("org.kidsos.Installer1"),
                              QStringLiteral("/org/kidsos/Installer1"),
                              QStringLiteral("org.kidsos.Installer1"), QDBusConnection::systemBus());
    if (!installer.isValid())
        return {};

    const QString childId = qEnvironmentVariable("USER");
    QDBusReply<QVariantList> reply = installer.call(QStringLiteral("ListRequests"), childId);
    return reply.isValid() ? reply.value() : QVariantList();
}

QVariantMap LauncherBridge::safetyStatus()
{
    QDBusInterface safety(QStringLiteral("org.kidsos.Safety1"), QStringLiteral("/org/kidsos/Safety1"),
                           QStringLiteral("org.kidsos.Safety1"), QDBusConnection::systemBus());
    if (!safety.isValid())
        return { { QStringLiteral("protectionActive"), false } };

    QDBusReply<QVariantMap> reply = safety.call(QStringLiteral("GetStatus"));
    return reply.isValid() ? reply.value() : QVariantMap { { QStringLiteral("protectionActive"), false } };
}

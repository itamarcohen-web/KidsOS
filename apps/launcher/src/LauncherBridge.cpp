#include "LauncherBridge.h"

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

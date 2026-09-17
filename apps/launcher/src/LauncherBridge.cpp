#include "LauncherBridge.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>

LauncherBridge::LauncherBridge(QObject *parent) : QObject(parent)
{
    const QString path = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                          + QStringLiteral("/kidsos/profile.json");
    QFile file(path);
    if (file.open(QIODevice::ReadOnly)) {
        const QJsonObject obj = QJsonDocument::fromJson(file.readAll()).object();
        m_profile = obj.toVariantMap();
    }
}

QVariantMap LauncherBridge::profile() const
{
    return m_profile;
}

bool LauncherBridge::launchCommand(const QString &command, const QStringList &args)
{
    if (command.isEmpty())
        return false;
    return QProcess::startDetached(command, args);
}

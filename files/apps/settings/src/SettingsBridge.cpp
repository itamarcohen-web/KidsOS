#include "SettingsBridge.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

#include <grp.h>
#include <pwd.h>
#include <unistd.h>

namespace {
QString configDir()
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                          + QStringLiteral("/kidsos");
    QDir().mkpath(base);
    return base;
}

bool currentUserInGroup(const char *groupName)
{
    struct group *grp = getgrnam(groupName);
    if (!grp)
        return false;

    struct passwd *pw = getpwuid(getuid());
    if (!pw)
        return false;
    if (pw->pw_gid == grp->gr_gid)
        return true;

    for (char **member = grp->gr_mem; *member != nullptr; ++member) {
        if (QString::fromLocal8Bit(*member) == QString::fromLocal8Bit(pw->pw_name))
            return true;
    }
    return false;
}
}

SettingsBridge::SettingsBridge(QObject *parent) : QObject(parent)
{
    QFile file(configDir() + QStringLiteral("/settings.json"));
    if (file.open(QIODevice::ReadOnly)) {
        const QJsonObject obj = QJsonDocument::fromJson(file.readAll()).object();
        const QString mode = obj.value(QStringLiteral("appearanceMode")).toString();
        if (!mode.isEmpty())
            m_appearanceMode = mode;
    }

    m_isChildAccount = currentUserInGroup("kidsos-children");
}

QString SettingsBridge::appearanceMode() const
{
    return m_appearanceMode;
}

bool SettingsBridge::isChildAccount() const
{
    return m_isChildAccount;
}

bool SettingsBridge::isSettingManaged(const QString &settingId) const
{
    // Only meaningful in a child session — a Parent's own settings are
    // never "managed by parent" (spec §28's banner is child-facing).
    if (!m_isChildAccount)
        return false;

    QDBusInterface policy(QStringLiteral("org.kidsos.Policy1"), QStringLiteral("/org/kidsos/Policy1"),
                           QStringLiteral("org.kidsos.Policy1"), QDBusConnection::systemBus());
    if (!policy.isValid())
        return false;

    QDBusReply<bool> reply = policy.call(QStringLiteral("IsSettingParentManaged"), settingId);
    return reply.isValid() && reply.value();
}

void SettingsBridge::saveAppearanceMode(const QString &mode)
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

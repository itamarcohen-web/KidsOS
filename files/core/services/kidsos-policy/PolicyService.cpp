#include "PolicyService.h"
#include "../common/AuditLog.h"
#include "../common/PolkitCheck.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

PolicyService::PolicyService(QObject *parent) : QObject(parent) { }

QString PolicyService::policyFilePath() const
{
    return QStringLiteral("/etc/kidsos/policy.json");
}

QString PolicyService::GetAppPolicy(const QString &appId)
{
    QFile file(policyFilePath());
    if (!file.open(QIODevice::ReadOnly))
        return QStringLiteral("ask_parent");

    const QJsonObject root = QJsonDocument::fromJson(file.readAll()).object();
    const QJsonObject apps = root.value(QStringLiteral("appPolicies")).toObject();
    return apps.value(appId).toString(QStringLiteral("ask_parent"));
}

bool PolicyService::IsSettingParentManaged(const QString &settingId)
{
    QFile file(policyFilePath());
    if (!file.open(QIODevice::ReadOnly))
        return false;

    const QJsonObject root = QJsonDocument::fromJson(file.readAll()).object();
    const QJsonArray managed = root.value(QStringLiteral("managedSettings")).toArray();
    for (const QJsonValue &v : managed) {
        if (v.toString() == settingId)
            return true;
    }
    return false;
}

bool PolicyService::SetAppPolicy(const QString &appId, const QString &policy,
                                  const QDBusMessage &message)
{
    if (!PolkitCheck::isAuthorized(message, QStringLiteral("org.kidsos.policy.manage")))
        return false;

    static const QStringList validPolicies = { QStringLiteral("auto"), QStringLiteral("ask_parent"),
                                                 QStringLiteral("blocked") };
    if (!validPolicies.contains(policy))
        return false;

    QFile file(policyFilePath());
    QJsonObject root;
    if (file.open(QIODevice::ReadOnly)) {
        root = QJsonDocument::fromJson(file.readAll()).object();
        file.close();
    }
    QJsonObject apps = root.value(QStringLiteral("appPolicies")).toObject();
    apps[appId] = policy;
    root[QStringLiteral("appPolicies")] = apps;

    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    file.close();

    AuditLog::record(QStringLiteral("policy.app_policy_changed"),
                      { { QStringLiteral("appId"), appId }, { QStringLiteral("policy"), policy } });
    return true;
}

bool PolicyService::SetSettingManaged(const QString &settingId, bool managed,
                                       const QDBusMessage &message)
{
    if (!PolkitCheck::isAuthorized(message, QStringLiteral("org.kidsos.policy.manage")))
        return false;

    QFile file(policyFilePath());
    QJsonObject root;
    if (file.open(QIODevice::ReadOnly)) {
        root = QJsonDocument::fromJson(file.readAll()).object();
        file.close();
    }
    QJsonArray settings = root.value(QStringLiteral("managedSettings")).toArray();
    for (int i = settings.size() - 1; i >= 0; --i) {
        if (settings.at(i) == QJsonValue(settingId))
            settings.removeAt(i);
    }
    if (managed)
        settings.append(settingId);
    root[QStringLiteral("managedSettings")] = settings;

    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    file.close();

    AuditLog::record(QStringLiteral("policy.setting_managed_changed"),
                      { { QStringLiteral("settingId"), settingId }, { QStringLiteral("managed"), managed } });
    return true;
}

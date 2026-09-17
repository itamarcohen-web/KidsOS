#include "ApprovalsBridge.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>

namespace {
QDBusInterface installerInterface()
{
    return QDBusInterface(QStringLiteral("org.kidsos.Installer1"),
                           QStringLiteral("/org/kidsos/Installer1"),
                           QStringLiteral("org.kidsos.Installer1"), QDBusConnection::systemBus());
}
}

ApprovalsBridge::ApprovalsBridge(QObject *parent) : QObject(parent) { }

QVariantList ApprovalsBridge::pendingRequests()
{
    QDBusInterface installer = installerInterface();
    QDBusReply<QVariantList> reply = installer.call(QStringLiteral("ListRequests"), QString());
    if (!reply.isValid())
        return {};

    QVariantList pending;
    for (const QVariant &v : reply.value()) {
        const QVariantMap row = v.toMap();
        if (row.value(QStringLiteral("status")).toString() == QStringLiteral("pending"))
            pending.append(row);
    }
    return pending;
}

QVariantList ApprovalsBridge::decidedRequests()
{
    QDBusInterface installer = installerInterface();
    QDBusReply<QVariantList> reply = installer.call(QStringLiteral("ListRequests"), QString());
    if (!reply.isValid())
        return {};

    QVariantList decided;
    for (const QVariant &v : reply.value()) {
        const QVariantMap row = v.toMap();
        if (row.value(QStringLiteral("status")).toString() != QStringLiteral("pending"))
            decided.append(row);
    }
    return decided;
}

QVariantList ApprovalsBridge::trustedApps()
{
    QDBusInterface installer = installerInterface();
    QDBusReply<QVariantList> reply = installer.call(QStringLiteral("ListTrustedApps"));
    return reply.isValid() ? reply.value() : QVariantList();
}

QString ApprovalsBridge::childDisplayName(const QString &childId) const
{
    QFile file(QStringLiteral("/var/lib/kidsos/profiles/%1.json").arg(childId));
    if (!file.open(QIODevice::ReadOnly))
        return childId;
    const QJsonObject obj = QJsonDocument::fromJson(file.readAll()).object();
    const QString name = obj.value(QStringLiteral("displayName")).toString();
    return name.isEmpty() ? childId : name;
}

bool ApprovalsBridge::approve(const QString &requestId)
{
    QDBusInterface installer = installerInterface();
    QDBusReply<bool> reply = installer.call(QStringLiteral("ApproveRequest"), requestId);
    return reply.isValid() && reply.value();
}

bool ApprovalsBridge::deny(const QString &requestId)
{
    QDBusInterface installer = installerInterface();
    QDBusReply<bool> reply = installer.call(QStringLiteral("DenyRequest"), requestId);
    return reply.isValid() && reply.value();
}

bool ApprovalsBridge::revoke(const QString &requestId)
{
    QDBusInterface installer = installerInterface();
    QDBusReply<bool> reply = installer.call(QStringLiteral("RevokeTrust"), requestId);
    return reply.isValid() && reply.value();
}

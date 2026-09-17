#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

// Bridges the Parent Approval app to org.kidsos.Installer1. Approve/
// Deny/Revoke calls are polkit-gated inside the service itself (see
// docs/SECURITY_ARCHITECTURE.md) — this class holds no privilege of its
// own; the OS's own polkit agent prompts for the Parent password.
class ApprovalsBridge : public QObject
{
    Q_OBJECT

public:
    explicit ApprovalsBridge(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList pendingRequests();
    Q_INVOKABLE QVariantList decidedRequests();
    Q_INVOKABLE QVariantList trustedApps();
    Q_INVOKABLE QString childDisplayName(const QString &childId) const;

    Q_INVOKABLE bool approve(const QString &requestId);
    Q_INVOKABLE bool deny(const QString &requestId);
    Q_INVOKABLE bool revoke(const QString &requestId);
};

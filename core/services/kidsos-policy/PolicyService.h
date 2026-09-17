#pragma once

#include <QDBusMessage>
#include <QObject>
#include <QString>

// org.kidsos.Policy1 — policy decisions, backed by /etc/kidsos/policy.json
// (root:kidsos-service, 0640). Runs as the unprivileged kidsos-service
// user — it only ever reads its own state file or asks polkit before
// writing it, so it never needs root. See docs/SECURITY_ARCHITECTURE.md.
class PolicyService : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kidsos.Policy1")

public:
    explicit PolicyService(QObject *parent = nullptr);

public Q_SLOTS:
    // "auto" | "ask_parent" | "blocked". Unknown app IDs default to
    // "ask_parent" — never silently "auto" (spec §20: unknown → block
    // until approval; "ask_parent" is the UX-facing form of that here,
    // since the child can still *request* it).
    Q_SCRIPTABLE QString GetAppPolicy(const QString &appId);
    Q_SCRIPTABLE bool IsSettingParentManaged(const QString &settingId);

    Q_SCRIPTABLE bool SetAppPolicy(const QString &appId, const QString &policy,
                                    const QDBusMessage &message);
    Q_SCRIPTABLE bool SetSettingManaged(const QString &settingId, bool managed,
                                         const QDBusMessage &message);

private:
    QString policyFilePath() const;
};

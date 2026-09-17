#pragma once

#include <QDBusMessage>
#include <QObject>
#include <QString>
#include <QVariantList>

#include "RequestStore.h"

// org.kidsos.Installer1 — the privileged installation workflow (spec
// §15, §17, §24-26). Runs as root. Every *mutating* call other than the
// two Submit* methods is polkit-gated (org.kidsos.installer.approve,
// auth_admin) so approval always requires live Parent authentication —
// see docs/SECURITY_ARCHITECTURE.md.
class InstallerService : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kidsos.Installer1")

public:
    explicit InstallerService(QObject *parent = nullptr);
    bool init();

public Q_SLOTS:
    // Kids Store path (spec §15). No approval gate to *submit* — any
    // child may ask; policy/Parent decide what happens next.
    Q_SCRIPTABLE QString SubmitInstallRequest(const QString &childId, const QString &appId,
                                               const QString &appName, const QString &source,
                                               const QStringList &permissions);

    // External file path (spec §17-18). Computes the file's classification
    // and SHA-256 itself — never trusts values passed by the caller.
    Q_SCRIPTABLE QString SubmitExternalInstallRequest(const QString &childId,
                                                        const QString &filePath,
                                                        const QString &sourceUrl);

    Q_SCRIPTABLE bool ApproveRequest(const QString &requestId, const QDBusMessage &message);
    Q_SCRIPTABLE bool DenyRequest(const QString &requestId, const QDBusMessage &message);
    Q_SCRIPTABLE QVariantList ListRequests(const QString &childId);
    Q_SCRIPTABLE QVariantList ListTrustedApps();
    Q_SCRIPTABLE bool RevokeTrust(const QString &requestId, const QDBusMessage &message);

private:
    bool approveExternal(const QVariantMap &request);
    bool approveStore(const QVariantMap &request);

    RequestStore m_store;
};

#pragma once

#include <QString>
#include <QVariantList>
#include <QVariantMap>

// SQLite-backed store for InstallRequest / ExternalInstallRequest (spec
// §15, §17). Lives at /var/lib/kidsos/installer/requests.db
// (root:root, 0600 — only kidsos-installer itself touches it; UI
// clients only ever see records through the D-Bus API).
class RequestStore
{
public:
    RequestStore();
    ~RequestStore();

    bool open();

    // Kids Store path (spec §15). permissions: e.g. ["internet","files"].
    QString insertStoreRequest(const QString &childId, const QString &appId,
                                const QString &appName, const QString &source,
                                const QStringList &permissions);

    // External file path (spec §17-18).
    QString insertExternalRequest(const QString &childId, const QString &filePath,
                                   const QString &fileType, const QString &fileHash,
                                   qint64 fileSize, const QString &sourceUrl);

    bool updateStatus(const QString &requestId, const QString &status);
    QVariantMap getRequest(const QString &requestId) const;
    QVariantList listRequests(const QString &childId) const; // empty childId = all (Parent view)

    // Trusted-app registry: hash -> {path, requestId, trustedAt}.
    // Backs ListTrustedApps/RevokeTrust in InstallerService.
    bool recordTrust(const QString &hash, const QString &path, const QString &requestId);
    bool removeTrust(const QString &hash);
    QVariantList listTrusted() const;

private:
    QString m_connectionName;
    static QString newRequestId();
};

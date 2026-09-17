#include "InstallerService.h"
#include "FileClassifier.h"
#include "../common/AuditLog.h"
#include "../common/PolkitCheck.h"

#include <QCryptographicHash>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QFile>
#include <QFileInfo>

namespace {

QString hashFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return QString();

    QCryptographicHash hash(QCryptographicHash::Sha256);
    if (!hash.addData(&file))
        return QString();
    return QString::fromLatin1(hash.result().toHex());
}

}

InstallerService::InstallerService(QObject *parent) : QObject(parent) { }

bool InstallerService::init()
{
    return m_store.open();
}

QString InstallerService::SubmitInstallRequest(const QString &childId, const QString &appId,
                                                const QString &appName, const QString &source,
                                                const QStringList &permissions)
{
    const QString id = m_store.insertStoreRequest(childId, appId, appName, source, permissions);
    AuditLog::record(QStringLiteral("install.request"),
                      { { QStringLiteral("requestId"), id }, { QStringLiteral("childId"), childId },
                        { QStringLiteral("appId"), appId }, { QStringLiteral("source"), source } });
    return id;
}

QString InstallerService::SubmitExternalInstallRequest(const QString &childId,
                                                         const QString &filePath,
                                                         const QString &sourceUrl)
{
    QFileInfo info(filePath);
    if (!info.exists() || !info.isFile())
        return QString();

    const QString kind = FileClassifier::classify(filePath);
    if (!FileClassifier::requiresApproval(kind)) {
        // Ordinary documents never generate a request — spec §21.
        return QString();
    }

    const QString hash = hashFile(filePath);
    if (hash.isEmpty())
        return QString();

    const QString id = m_store.insertExternalRequest(childId, filePath, kind, hash, info.size(),
                                                       sourceUrl);
    AuditLog::record(QStringLiteral("external.request"),
                      { { QStringLiteral("requestId"), id }, { QStringLiteral("childId"), childId },
                        { QStringLiteral("fileType"), kind }, { QStringLiteral("fileHash"), hash } });
    return id;
}

bool InstallerService::approveExternal(const QVariantMap &request)
{
    const QString path = request.value(QStringLiteral("file_path")).toString();
    const QString approvedHash = request.value(QStringLiteral("file_hash")).toString();
    const QString requestId = request.value(QStringLiteral("id")).toString();

    // Re-hash at approval time. Any difference from the hash captured at
    // submission means the file changed underneath the request — spec
    // §25 requires rejecting outright, not silently re-approving the new
    // content.
    QFileInfo info(path);
    if (!info.exists()) {
        AuditLog::record(QStringLiteral("external.approve.failed"),
                          { { QStringLiteral("requestId"), requestId }, { QStringLiteral("reason"), QStringLiteral("file_missing") } });
        return false;
    }
    const QString currentHash = hashFile(path);
    if (currentHash != approvedHash) {
        AuditLog::record(QStringLiteral("external.approve.failed"),
                          { { QStringLiteral("requestId"), requestId }, { QStringLiteral("reason"), QStringLiteral("hash_mismatch") } });
        return false;
    }

    QDBusInterface fileGuard(QStringLiteral("org.kidsos.FileGuard1"),
                              QStringLiteral("/org/kidsos/FileGuard1"),
                              QStringLiteral("org.kidsos.FileGuard1"), QDBusConnection::systemBus());
    if (!fileGuard.isValid())
        return false;

    QDBusReply<bool> trustReply = fileGuard.call(QStringLiteral("TrustFile"), currentHash, path);
    if (!trustReply.isValid() || !trustReply.value())
        return false;

    m_store.recordTrust(currentHash, path, requestId);
    return true;
}

bool InstallerService::approveStore(const QVariantMap & /*request*/)
{
    // Kids Store has no real app catalog/backend yet (see
    // docs/ROADMAP.md) — approval records the decision so the UI can
    // reflect it, but does not trigger an install. Statuses stop at
    // "approved" rather than progressing to "installed" until a real
    // catalog exists.
    return true;
}

bool InstallerService::ApproveRequest(const QString &requestId, const QDBusMessage &message)
{
    if (!PolkitCheck::isAuthorized(message, QStringLiteral("org.kidsos.installer.approve")))
        return false;

    const QVariantMap request = m_store.getRequest(requestId);
    if (request.isEmpty() || request.value(QStringLiteral("status")).toString() != QStringLiteral("pending"))
        return false;

    const QString kind = request.value(QStringLiteral("kind")).toString();
    const bool ok = kind == QStringLiteral("external") ? approveExternal(request) : approveStore(request);

    m_store.updateStatus(requestId, ok ? QStringLiteral("approved") : QStringLiteral("failed"));
    AuditLog::record(kind == QStringLiteral("external") ? QStringLiteral("external.approve")
                                                          : QStringLiteral("install.approve"),
                      { { QStringLiteral("requestId"), requestId }, { QStringLiteral("ok"), ok } });
    return ok;
}

bool InstallerService::DenyRequest(const QString &requestId, const QDBusMessage &message)
{
    if (!PolkitCheck::isAuthorized(message, QStringLiteral("org.kidsos.installer.approve")))
        return false;

    const QVariantMap request = m_store.getRequest(requestId);
    if (request.isEmpty())
        return false;

    const bool ok = m_store.updateStatus(requestId, QStringLiteral("denied"));
    AuditLog::record(request.value(QStringLiteral("kind")).toString() == QStringLiteral("external")
                          ? QStringLiteral("external.deny")
                          : QStringLiteral("install.deny"),
                      { { QStringLiteral("requestId"), requestId } });
    return ok;
}

QVariantList InstallerService::ListRequests(const QString &childId)
{
    return m_store.listRequests(childId);
}

QVariantList InstallerService::ListTrustedApps()
{
    return m_store.listTrusted();
}

bool InstallerService::RevokeTrust(const QString &requestId, const QDBusMessage &message)
{
    if (!PolkitCheck::isAuthorized(message, QStringLiteral("org.kidsos.installer.approve")))
        return false;

    const QVariantMap request = m_store.getRequest(requestId);
    const QString hash = request.value(QStringLiteral("file_hash")).toString();
    if (hash.isEmpty())
        return false;

    QDBusInterface fileGuard(QStringLiteral("org.kidsos.FileGuard1"),
                              QStringLiteral("/org/kidsos/FileGuard1"),
                              QStringLiteral("org.kidsos.FileGuard1"), QDBusConnection::systemBus());
    QDBusReply<bool> revokeReply = fileGuard.call(QStringLiteral("RevokeFile"), hash);
    if (!revokeReply.isValid() || !revokeReply.value())
        return false;

    m_store.removeTrust(hash);
    m_store.updateStatus(requestId, QStringLiteral("denied"));
    AuditLog::record(QStringLiteral("trust.revoke"), { { QStringLiteral("requestId"), requestId } });
    return true;
}

#include "RequestStore.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QUuid>

namespace {
const QString kDbPath = QStringLiteral("/var/lib/kidsos/installer/requests.db");
}

RequestStore::RequestStore() : m_connectionName(QStringLiteral("kidsos-installer")) { }

RequestStore::~RequestStore()
{
    QSqlDatabase::removeDatabase(m_connectionName);
}

QString RequestStore::newRequestId()
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

bool RequestStore::open()
{
    QDir().mkpath(QStringLiteral("/var/lib/kidsos/installer"));

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName);
    db.setDatabaseName(kDbPath);
    if (!db.open())
        return false;

    QFile::setPermissions(kDbPath, QFile::ReadOwner | QFile::WriteOwner);

    QSqlQuery q(db);
    const bool ok = q.exec(QStringLiteral(R"SQL(
        CREATE TABLE IF NOT EXISTS requests (
            id TEXT PRIMARY KEY,
            kind TEXT NOT NULL,
            child_id TEXT NOT NULL,
            app_id TEXT,
            app_name TEXT,
            source TEXT,
            permissions TEXT,
            file_path TEXT,
            file_type TEXT,
            file_hash TEXT,
            file_size INTEGER,
            source_url TEXT,
            status TEXT NOT NULL,
            requested_at TEXT NOT NULL,
            decided_at TEXT
        )
    )SQL"));
    if (!ok)
        return false;

    return q.exec(QStringLiteral(R"SQL(
        CREATE TABLE IF NOT EXISTS trusted_apps (
            hash TEXT PRIMARY KEY,
            path TEXT NOT NULL,
            request_id TEXT NOT NULL,
            trusted_at TEXT NOT NULL
        )
    )SQL"));
}

QString RequestStore::insertStoreRequest(const QString &childId, const QString &appId,
                                          const QString &appName, const QString &source,
                                          const QStringList &permissions)
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT INTO requests (id, kind, child_id, app_id, app_name, source, permissions, status, requested_at) "
        "VALUES (:id, 'store', :childId, :appId, :appName, :source, :permissions, 'pending', :requestedAt)"));
    const QString id = newRequestId();
    q.bindValue(QStringLiteral(":id"), id);
    q.bindValue(QStringLiteral(":childId"), childId);
    q.bindValue(QStringLiteral(":appId"), appId);
    q.bindValue(QStringLiteral(":appName"), appName);
    q.bindValue(QStringLiteral(":source"), source);
    q.bindValue(QStringLiteral(":permissions"), permissions.join(QStringLiteral(",")));
    q.bindValue(QStringLiteral(":requestedAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
    return q.exec() ? id : QString();
}

QString RequestStore::insertExternalRequest(const QString &childId, const QString &filePath,
                                             const QString &fileType, const QString &fileHash,
                                             qint64 fileSize, const QString &sourceUrl)
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT INTO requests (id, kind, child_id, file_path, file_type, file_hash, file_size, source_url, status, requested_at) "
        "VALUES (:id, 'external', :childId, :filePath, :fileType, :fileHash, :fileSize, :sourceUrl, 'pending', :requestedAt)"));
    const QString id = newRequestId();
    q.bindValue(QStringLiteral(":id"), id);
    q.bindValue(QStringLiteral(":childId"), childId);
    q.bindValue(QStringLiteral(":filePath"), filePath);
    q.bindValue(QStringLiteral(":fileType"), fileType);
    q.bindValue(QStringLiteral(":fileHash"), fileHash);
    q.bindValue(QStringLiteral(":fileSize"), fileSize);
    q.bindValue(QStringLiteral(":sourceUrl"), sourceUrl);
    q.bindValue(QStringLiteral(":requestedAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
    return q.exec() ? id : QString();
}

bool RequestStore::updateStatus(const QString &requestId, const QString &status)
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral("UPDATE requests SET status = :status, decided_at = :decidedAt WHERE id = :id"));
    q.bindValue(QStringLiteral(":status"), status);
    q.bindValue(QStringLiteral(":decidedAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
    q.bindValue(QStringLiteral(":id"), requestId);
    return q.exec() && q.numRowsAffected() > 0;
}

QVariantMap RequestStore::getRequest(const QString &requestId) const
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral("SELECT * FROM requests WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), requestId);
    if (!q.exec() || !q.next())
        return {};

    QVariantMap result;
    const QSqlRecord record = q.record();
    for (int i = 0; i < record.count(); ++i)
        result[record.fieldName(i)] = q.value(i);
    return result;
}

QVariantList RequestStore::listRequests(const QString &childId) const
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    if (childId.isEmpty()) {
        q.prepare(QStringLiteral("SELECT * FROM requests ORDER BY requested_at DESC"));
    } else {
        q.prepare(QStringLiteral("SELECT * FROM requests WHERE child_id = :childId ORDER BY requested_at DESC"));
        q.bindValue(QStringLiteral(":childId"), childId);
    }
    if (!q.exec())
        return {};

    QVariantList results;
    while (q.next()) {
        QVariantMap row;
        const QSqlRecord record = q.record();
        for (int i = 0; i < record.count(); ++i)
            row[record.fieldName(i)] = q.value(i);
        results.append(row);
    }
    return results;
}

bool RequestStore::recordTrust(const QString &hash, const QString &path, const QString &requestId)
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT OR REPLACE INTO trusted_apps (hash, path, request_id, trusted_at) VALUES (:hash, :path, :requestId, :trustedAt)"));
    q.bindValue(QStringLiteral(":hash"), hash);
    q.bindValue(QStringLiteral(":path"), path);
    q.bindValue(QStringLiteral(":requestId"), requestId);
    q.bindValue(QStringLiteral(":trustedAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
    return q.exec();
}

bool RequestStore::removeTrust(const QString &hash)
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral("DELETE FROM trusted_apps WHERE hash = :hash"));
    q.bindValue(QStringLiteral(":hash"), hash);
    return q.exec();
}

QVariantList RequestStore::listTrusted() const
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    if (!q.exec(QStringLiteral("SELECT * FROM trusted_apps ORDER BY trusted_at DESC")))
        return {};

    QVariantList results;
    while (q.next()) {
        QVariantMap row;
        const QSqlRecord record = q.record();
        for (int i = 0; i < record.count(); ++i)
            row[record.fieldName(i)] = q.value(i);
        results.append(row);
    }
    return results;
}

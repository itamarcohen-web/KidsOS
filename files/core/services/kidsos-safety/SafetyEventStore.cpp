#include "SafetyEventStore.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QUuid>

namespace {
const QString kDbPath = QStringLiteral("/var/lib/kidsos/safety/events.db");
}

SafetyEventStore::SafetyEventStore() : m_connectionName(QStringLiteral("kidsos-safety")) { }

SafetyEventStore::~SafetyEventStore()
{
    QSqlDatabase::removeDatabase(m_connectionName);
}

QString SafetyEventStore::newEventId()
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

bool SafetyEventStore::open()
{
    QDir().mkpath(QStringLiteral("/var/lib/kidsos/safety"));

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName);
    db.setDatabaseName(kDbPath);
    if (!db.open())
        return false;

    QFile::setPermissions(kDbPath, QFile::ReadOwner | QFile::WriteOwner);

    QSqlQuery q(db);
    bool ok = q.exec(QStringLiteral(R"SQL(
        CREATE TABLE IF NOT EXISTS safety_events (
            id TEXT PRIMARY KEY,
            timestamp TEXT NOT NULL,
            child_id TEXT NOT NULL,
            application TEXT,
            category TEXT NOT NULL,
            severity TEXT NOT NULL,
            confidence REAL NOT NULL,
            summary TEXT,
            evidence_reference TEXT,
            capture_quality TEXT,
            ai_model_version TEXT
        )
    )SQL"));
    if (!ok)
        return false;

    ok = q.exec(QStringLiteral(R"SQL(
        CREATE TABLE IF NOT EXISTS analysis_runs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            child_id TEXT NOT NULL,
            application TEXT,
            duration_ms INTEGER,
            stage TEXT,
            ran_at TEXT NOT NULL
        )
    )SQL"));
    if (!ok)
        return false;

    ok = q.exec(QStringLiteral(R"SQL(
        CREATE TABLE IF NOT EXISTS model_versions (
            model_name TEXT PRIMARY KEY,
            version TEXT NOT NULL,
            provider TEXT NOT NULL,
            recorded_at TEXT NOT NULL
        )
    )SQL"));
    if (!ok)
        return false;

    return q.exec(QStringLiteral(R"SQL(
        CREATE TABLE IF NOT EXISTS policy_state (
            key TEXT PRIMARY KEY,
            value TEXT
        )
    )SQL"));
}

QString SafetyEventStore::insertEvent(const SafetyAi::SafetyEvent &event, const QString &modelVersion)
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT INTO safety_events (id, timestamp, child_id, application, category, severity, "
        "confidence, summary, evidence_reference, capture_quality, ai_model_version) "
        "VALUES (:id, :timestamp, :childId, :application, :category, :severity, :confidence, "
        ":summary, :evidenceReference, :captureQuality, :modelVersion)"));
    const QString id = event.id.isEmpty() ? newEventId() : event.id;
    q.bindValue(QStringLiteral(":id"), id);
    q.bindValue(QStringLiteral(":timestamp"),
                (event.timestamp.isValid() ? event.timestamp : QDateTime::currentDateTimeUtc()).toUTC().toString(Qt::ISODate));
    q.bindValue(QStringLiteral(":childId"), event.childId);
    q.bindValue(QStringLiteral(":application"), event.application);
    q.bindValue(QStringLiteral(":category"), SafetyAi::categoryToString(event.category));
    q.bindValue(QStringLiteral(":severity"), SafetyAi::severityToString(event.severity));
    q.bindValue(QStringLiteral(":confidence"), event.confidence);
    q.bindValue(QStringLiteral(":summary"), event.summary);
    q.bindValue(QStringLiteral(":evidenceReference"), event.evidenceReference);
    q.bindValue(QStringLiteral(":captureQuality"), event.captureQuality);
    q.bindValue(QStringLiteral(":modelVersion"), modelVersion);

    if (!q.exec())
        return QString();

    setPolicyState(QStringLiteral("lastCheckAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
    return id;
}

QVariantMap SafetyEventStore::getEvent(const QString &eventId) const
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral("SELECT * FROM safety_events WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), eventId);
    if (!q.exec() || !q.next())
        return {};

    QVariantMap result;
    const QSqlRecord record = q.record();
    for (int i = 0; i < record.count(); ++i)
        result[record.fieldName(i)] = q.value(i);
    return result;
}

QVariantList SafetyEventStore::listEvents(const QString &childId, int limit) const
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    if (childId.isEmpty()) {
        q.prepare(QStringLiteral("SELECT * FROM safety_events ORDER BY timestamp DESC LIMIT :limit"));
    } else {
        q.prepare(QStringLiteral(
            "SELECT * FROM safety_events WHERE child_id = :childId ORDER BY timestamp DESC LIMIT :limit"));
        q.bindValue(QStringLiteral(":childId"), childId);
    }
    q.bindValue(QStringLiteral(":limit"), limit);
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

void SafetyEventStore::recordAnalysisRun(const QString &childId, const QString &application,
                                          qint64 durationMs, const QString &stage)
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT INTO analysis_runs (child_id, application, duration_ms, stage, ran_at) "
        "VALUES (:childId, :application, :durationMs, :stage, :ranAt)"));
    q.bindValue(QStringLiteral(":childId"), childId);
    q.bindValue(QStringLiteral(":application"), application);
    q.bindValue(QStringLiteral(":durationMs"), durationMs);
    q.bindValue(QStringLiteral(":stage"), stage);
    q.bindValue(QStringLiteral(":ranAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
    q.exec();
}

void SafetyEventStore::recordModelVersion(const QString &modelName, const QString &version,
                                           const QString &provider)
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT OR REPLACE INTO model_versions (model_name, version, provider, recorded_at) "
        "VALUES (:name, :version, :provider, :recordedAt)"));
    q.bindValue(QStringLiteral(":name"), modelName);
    q.bindValue(QStringLiteral(":version"), version);
    q.bindValue(QStringLiteral(":provider"), provider);
    q.bindValue(QStringLiteral(":recordedAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
    q.exec();
}

void SafetyEventStore::setPolicyState(const QString &key, const QString &value)
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO policy_state (key, value) VALUES (:key, :value)"));
    q.bindValue(QStringLiteral(":key"), key);
    q.bindValue(QStringLiteral(":value"), value);
    q.exec();
}

QString SafetyEventStore::policyState(const QString &key) const
{
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral("SELECT value FROM policy_state WHERE key = :key"));
    q.bindValue(QStringLiteral(":key"), key);
    if (!q.exec() || !q.next())
        return QString();
    return q.value(0).toString();
}

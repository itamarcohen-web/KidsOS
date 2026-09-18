#pragma once

#include "../common/safety/SafetyTypes.h"

#include <QVariantList>
#include <QVariantMap>

// SQLite-backed store for SafetyEvents (spec §21). Lives at
// /var/lib/kidsos/safety/events.db (root:kidsos-service, 0600 — same
// tamper-resistance pattern as kidsos-installer's RequestStore: the
// Child-session agent that *produces* events never has file access to
// this database, it can only submit events through kidsos-safety's
// D-Bus API, which is the only thing that ever opens this file).
class SafetyEventStore
{
public:
    SafetyEventStore();
    ~SafetyEventStore();

    bool open();

    // Returns the new event's id, or an empty string on failure.
    QString insertEvent(const SafetyAi::SafetyEvent &event, const QString &modelVersion);

    QVariantMap getEvent(const QString &eventId) const;
    // childId empty = all children (Parent overview). Newest first.
    QVariantList listEvents(const QString &childId, int limit = 100) const;

    void recordAnalysisRun(const QString &childId, const QString &application,
                            qint64 durationMs, const QString &stage);

    void recordModelVersion(const QString &modelName, const QString &version,
                             const QString &provider);

    // policy_state is a tiny key/value table used for status queries
    // that don't warrant their own columns, e.g. "lastCheckAt".
    void setPolicyState(const QString &key, const QString &value);
    QString policyState(const QString &key) const;

private:
    QString m_connectionName;
    static QString newEventId();
};

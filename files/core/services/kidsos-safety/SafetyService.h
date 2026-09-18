#pragma once

#include "../common/safety/SafetyPolicy.h"
#include "SafetyEventStore.h"

#include <QDBusMessage>
#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

// org.kidsos.Safety1 — the privileged half of the Local Safety AI System
// (Milestone 4, spec §18/§21/§29/§34). Runs unprivileged as
// kidsos-service, same as kidsos-policy. Owns the events database and
// the safety-policy.json thresholds; kidsos-safety-agent (which runs in
// the Child's own session, since screen capture must originate there —
// see docs/SAFETY_AI.md) never touches either directly, only through
// ReportEvent below.
//
// ReportEvent itself is deliberately *not* polkit-gated: it's called by
// the Child-session agent, which has no Parent credentials to offer.
// The D-Bus system policy (org.kidsos.Safety1.conf) is what restricts
// who may even reach this bus name; ReportEvent additionally checks
// that the caller isn't the Parent account (spec §5: only the Child
// session is analyzed).
class SafetyService : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kidsos.Safety1")

public:
    explicit SafetyService(QObject *parent = nullptr);
    bool init();

public Q_SLOTS:
    // event: the SafetyAi::toExportSchema()-shaped map, plus "childId"
    // and "captureQuality". Returns the stored event id, or an empty
    // string if the sender was rejected or storage failed.
    Q_SCRIPTABLE QString ReportEvent(const QVariantMap &event, const QDBusMessage &message);

    // Called by kidsos-safety-agent for every sample that came back
    // SAFE (spec §19: those are discarded immediately, never stored),
    // purely so GetStatus()'s "last check" timestamp still reflects
    // reality — see docs/SAFETY_AI.md.
    Q_SCRIPTABLE void Heartbeat();

    // Non-sensitive status for the Safety status indicator (spec §34) —
    // never exposes event content, only "is protection active" and
    // "how long ago was the last check".
    Q_SCRIPTABLE QVariantMap GetStatus();

    // Parent-only (org.kidsos.safety.review): the actual event history,
    // for a future Parent-facing review screen.
    Q_SCRIPTABLE QVariantList GetRecentEvents(const QString &childId, int limit,
                                                const QDBusMessage &message);

    // Parent-only (org.kidsos.safety.manage): spec §29's configurable
    // thresholds.
    Q_SCRIPTABLE bool SetThreshold(const QString &name, double value, const QDBusMessage &message);
    Q_SCRIPTABLE QVariantMap GetThresholds();

private:
    SafetyEventStore m_store;
    SafetyPolicy m_policy;
};

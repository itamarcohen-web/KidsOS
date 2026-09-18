#include "SafetyService.h"

#include "../common/AuditLog.h"
#include "../common/PolkitCheck.h"
#include "../common/safety/SafetyTypes.h"

#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDateTime>

#include <grp.h>
#include <pwd.h>

namespace {

// Same "real Linux group membership, not a flag file" check used by
// files/system/usr/bin/kidsos-session-start (see
// docs/ACCOUNTS_AND_LOGIN.md) — ported to C++ since this is the first
// D-Bus service that needs to draw the Parent/Child distinction itself
// rather than leaving it to a shell script.
bool uidIsInGroup(uint uid, const char *groupName)
{
    const passwd *pw = getpwuid(uid);
    if (!pw)
        return false;

    const group *gr = getgrnam(groupName);
    if (!gr)
        return false;
    if (pw->pw_gid == gr->gr_gid)
        return true;

    for (char **member = gr->gr_mem; member && *member; ++member) {
        if (QString::fromLocal8Bit(pw->pw_name) == QString::fromLocal8Bit(*member))
            return true;
    }
    return false;
}

}

SafetyService::SafetyService(QObject *parent) : QObject(parent) { }

bool SafetyService::init()
{
    m_policy.load();
    return m_store.open();
}

QString SafetyService::ReportEvent(const QVariantMap &event, const QDBusMessage &message)
{
    QDBusConnection bus = QDBusConnection::systemBus();
    const uint senderUid = bus.interface()->serviceUid(message.service());

    // spec §5: only the Child session is analyzed. A caller running as
    // the Parent (wheel group) is rejected outright — this also means a
    // compromised Parent process can't inject fabricated events either.
    if (uidIsInGroup(senderUid, "wheel")) {
        AuditLog::record(QStringLiteral("safety.event_rejected_wrong_session"),
                          { { QStringLiteral("uid"), senderUid } });
        return QString();
    }

    SafetyAi::SafetyEvent safetyEvent;
    safetyEvent.childId = event.value(QStringLiteral("childId")).toString();
    safetyEvent.application = event.value(QStringLiteral("application")).toString();
    safetyEvent.category = SafetyAi::categoryFromString(event.value(QStringLiteral("category")).toString());
    safetyEvent.severity = SafetyAi::severityFromString(event.value(QStringLiteral("severity")).toString());
    safetyEvent.confidence = event.value(QStringLiteral("confidence")).toDouble();
    safetyEvent.summary = event.value(QStringLiteral("summary")).toString();
    safetyEvent.evidenceReference = event.value(QStringLiteral("evidenceReference")).toString();
    safetyEvent.captureQuality = event.value(QStringLiteral("captureQuality")).toString();
    safetyEvent.timestamp = QDateTime::currentDateTimeUtc();

    const QString modelVersion = event.value(QStringLiteral("modelVersion")).toString();
    const QString id = m_store.insertEvent(safetyEvent, modelVersion);
    if (id.isEmpty())
        return QString();

    // Only MEDIUM+ is audit-logged (spec §19's discard-by-default for
    // SAFE/LOW keeps the journal from filling up with routine samples,
    // while still giving Parent-visible tooling a record of anything
    // that mattered).
    if (safetyEvent.severity != SafetyAi::Severity::Safe && safetyEvent.severity != SafetyAi::Severity::Low) {
        AuditLog::record(QStringLiteral("safety.event_recorded"),
                          { { QStringLiteral("category"), SafetyAi::categoryToString(safetyEvent.category) },
                            { QStringLiteral("severity"), SafetyAi::severityToString(safetyEvent.severity) } });
    }

    return id;
}

void SafetyService::Heartbeat()
{
    m_store.setPolicyState(QStringLiteral("lastCheckAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
}

QVariantMap SafetyService::GetStatus()
{
    const QString lastCheckAt = m_store.policyState(QStringLiteral("lastCheckAt"));
    return QVariantMap {
        { QStringLiteral("protectionActive"), true },
        { QStringLiteral("lastCheckAt"), lastCheckAt },
    };
}

QVariantList SafetyService::GetRecentEvents(const QString &childId, int limit, const QDBusMessage &message)
{
    if (!PolkitCheck::isAuthorized(message, QStringLiteral("org.kidsos.safety.review")))
        return {};
    return m_store.listEvents(childId, limit > 0 ? limit : 100);
}

bool SafetyService::SetThreshold(const QString &name, double value, const QDBusMessage &message)
{
    if (!PolkitCheck::isAuthorized(message, QStringLiteral("org.kidsos.safety.manage")))
        return false;

    m_policy.setThreshold(name, value);
    const bool ok = m_policy.save();
    if (ok) {
        AuditLog::record(QStringLiteral("safety.threshold_changed"),
                          { { QStringLiteral("name"), name }, { QStringLiteral("value"), value } });
    }
    return ok;
}

QVariantMap SafetyService::GetThresholds()
{
    return QVariantMap {
        { QStringLiteral("safeThreshold"), m_policy.safeThreshold() },
        { QStringLiteral("mediumThreshold"), m_policy.mediumThreshold() },
        { QStringLiteral("highThreshold"), m_policy.highThreshold() },
        { QStringLiteral("criticalThreshold"), m_policy.criticalThreshold() },
    };
}

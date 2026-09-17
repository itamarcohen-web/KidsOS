#include "PolkitCheck.h"

#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusError>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDebug>
#include <QFile>
#include <QVariantMap>

namespace {

// polkit's Subject struct needs the process start time (field 22 of
// /proc/<pid>/stat) to disambiguate a PID from a since-exited, reused
// one. Reading it ourselves (rather than passing 0) is what pkexec and
// every other real polkit client does.
quint64 processStartTime(quint32 pid)
{
    QFile statFile(QStringLiteral("/proc/%1/stat").arg(pid));
    if (!statFile.open(QIODevice::ReadOnly))
        return 0;
    const QByteArray data = statFile.readAll();
    // Field 2 (comm) may contain spaces/parens, so split after the last ')'.
    const int closeParen = data.lastIndexOf(')');
    if (closeParen < 0)
        return 0;
    const QList<QByteArray> fields = data.mid(closeParen + 2).split(' ');
    // After comm: state(1) ppid(2) ... starttime is field 22 overall,
    // i.e. index 19 in this post-comm split (0-based).
    if (fields.size() <= 19)
        return 0;
    return fields.at(19).toULongLong();
}

}

bool PolkitCheck::isAuthorized(const QDBusMessage &callerMessage, const QString &actionId,
                                bool interactive)
{
    const QString sender = callerMessage.service();
    if (sender.isEmpty()) {
        qWarning() << "PolkitCheck: no D-Bus sender on message, denying" << actionId;
        return false;
    }

    QDBusConnection bus = QDBusConnection::systemBus();

    QDBusReply<uint> pidReply = bus.interface()->call(
        QStringLiteral("GetConnectionUnixProcessID"), sender);
    if (!pidReply.isValid()) {
        qWarning() << "PolkitCheck: could not resolve sender PID:" << pidReply.error().message();
        return false;
    }
    const quint32 pid = pidReply.value();
    const quint64 startTime = processStartTime(pid);

    QDBusInterface authority(QStringLiteral("org.freedesktop.PolicyKit1"),
                              QStringLiteral("/org/freedesktop/PolicyKit1/Authority"),
                              QStringLiteral("org.freedesktop.PolicyKit1.Authority"),
                              bus);
    if (!authority.isValid()) {
        qWarning() << "PolkitCheck: polkit authority unavailable:" << authority.lastError().message();
        return false;
    }

    // Subject: (sa{sv}) — "unix-process" { pid, start-time }.
    QVariantMap subjectDetails;
    subjectDetails[QStringLiteral("pid")] = pid;
    subjectDetails[QStringLiteral("start-time")] = startTime;

    QDBusArgument subjectArg;
    subjectArg.beginStructure();
    subjectArg << QStringLiteral("unix-process") << subjectDetails;
    subjectArg.endStructure();

    const QVariantMap details; // no extra context shown in the auth dialog
    const uint flags = interactive ? 1u : 0u; // CheckAuthorizationFlags::AllowUserInteraction
    const QString cancellationId;

    QDBusReply<QDBusArgument> reply = authority.call(
        QStringLiteral("CheckAuthorization"), QVariant::fromValue(subjectArg), actionId,
        details, flags, cancellationId);

    if (!reply.isValid()) {
        qWarning() << "PolkitCheck: CheckAuthorization failed:" << reply.error().message();
        return false;
    }

    // AuthorizationResult: (bba{ss}) — is_authorized, is_challenge, details.
    QDBusArgument resultArg = reply.value();
    bool isAuthorized = false;
    resultArg.beginStructure();
    resultArg >> isAuthorized;
    resultArg.endStructure();

    return isAuthorized;
}

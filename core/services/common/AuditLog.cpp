#include "AuditLog.h"

#include <systemd/sd-journal.h>

#include <QByteArray>
#include <QDateTime>
#include <QList>

void AuditLog::record(const QString &action, const QVariantMap &fields)
{
    QList<QByteArray> storage;
    storage.reserve(fields.size() + 4);

    storage.append("MESSAGE=KidsOS audit: " + action.toUtf8());
    storage.append(QByteArrayLiteral("KIDSOS_AUDIT=1"));
    storage.append("KIDSOS_ACTION=" + action.toUtf8());
    storage.append("KIDSOS_TIMESTAMP=" + QDateTime::currentDateTimeUtc().toString(Qt::ISODate).toUtf8());

    for (auto it = fields.constBegin(); it != fields.constEnd(); ++it) {
        // journald field names: uppercase ASCII/digits/underscore, must
        // not start with a digit. "KIDSOS_" + upper(key) satisfies that
        // as long as the key itself is a simple identifier, which every
        // call site in this codebase uses.
        QString field = QStringLiteral("KIDSOS_") + it.key().toUpper();
        storage.append((field + QStringLiteral("=") + it.value().toString()).toUtf8());
    }

    QList<struct iovec> iov;
    iov.reserve(storage.size());
    for (const QByteArray &entry : storage)
        iov.append({ const_cast<char *>(entry.constData()), static_cast<size_t>(entry.size()) });

    sd_journal_sendv(iov.constData(), iov.size());
}

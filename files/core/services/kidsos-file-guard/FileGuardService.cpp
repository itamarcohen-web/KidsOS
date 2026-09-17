#include "FileGuardService.h"
#include "../common/AuditLog.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>
#include <QTextStream>

FileGuardService::FileGuardService(QObject *parent) : QObject(parent) { }

QString FileGuardService::trustFilePath() const
{
    return QStringLiteral("/etc/fapolicyd/trust.d/kidsos-approved.trust");
}

bool FileGuardService::reloadFapolicyd() const
{
    // Reloads fapolicyd's trust database from trust.d/ without a full
    // daemon restart. Verify this exact subcommand against the fapolicyd
    // version actually shipped in the base image — see
    // docs/TRUST_MODEL.md's "what this milestone does not claim".
    return QProcess::execute(QStringLiteral("fapolicyd-cli"), { QStringLiteral("--update") }) == 0;
}

bool FileGuardService::TrustFile(const QString &hash, const QString &path)
{
    static const QRegularExpression hexHash(QStringLiteral("^[0-9a-f]{64}$"));
    if (!hexHash.match(hash).hasMatch())
        return false;

    QFileInfo info(path);
    if (!info.exists())
        return false;

    QDir().mkpath(QStringLiteral("/etc/fapolicyd/trust.d"));

    // fapolicyd trust file format: "<absolute path> <size> <sha256>",
    // one entry per line. Rewriting the whole file (rather than
    // appending) also lets RevokeFile simply filter a line back out.
    QFile file(trustFilePath());
    QStringList lines;
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        while (!in.atEnd()) {
            const QString line = in.readLine();
            if (!line.contains(hash))
                lines << line;
        }
        file.close();
    }
    lines << QStringLiteral("%1 %2 %3").arg(path).arg(info.size()).arg(hash);

    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
        return false;
    QTextStream out(&file);
    for (const QString &line : lines)
        out << line << '\n';
    file.close();
    QFile::setPermissions(trustFilePath(), QFile::ReadOwner | QFile::WriteOwner | QFile::ReadGroup);

    const bool reloaded = reloadFapolicyd();
    AuditLog::record(QStringLiteral("file_guard.trust"),
                      { { QStringLiteral("hash"), hash }, { QStringLiteral("path"), path },
                        { QStringLiteral("reloaded"), reloaded } });
    return reloaded;
}

bool FileGuardService::RevokeFile(const QString &hash)
{
    QFile file(trustFilePath());
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    QStringList lines;
    QTextStream in(&file);
    while (!in.atEnd()) {
        const QString line = in.readLine();
        if (!line.contains(hash))
            lines << line;
    }
    file.close();

    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
        return false;
    QTextStream out(&file);
    for (const QString &line : lines)
        out << line << '\n';
    file.close();

    const bool reloaded = reloadFapolicyd();
    AuditLog::record(QStringLiteral("trust.revoke.file_guard"),
                      { { QStringLiteral("hash"), hash }, { QStringLiteral("reloaded"), reloaded } });
    return reloaded;
}

bool FileGuardService::IsTrusted(const QString &hash)
{
    QFile file(trustFilePath());
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    QTextStream in(&file);
    while (!in.atEnd()) {
        if (in.readLine().contains(hash))
            return true;
    }
    return false;
}

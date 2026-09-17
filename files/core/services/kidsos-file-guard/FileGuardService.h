#pragma once

#include <QObject>
#include <QString>

// org.kidsos.FileGuard1 — manages the fapolicyd trust file that actually
// enforces external-application blocking (spec §17-22). Runs as root
// (edits /etc/fapolicyd/trust.d/ and reloads the daemon). D-Bus policy
// (core/configuration/dbus-1/system.d/org.kidsos.FileGuard1.conf)
// restricts every method to the kidsos-installer service user — this
// object is not meant to be called by anything else, including the
// child's own UI. See docs/TRUST_MODEL.md.
class FileGuardService : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kidsos.FileGuard1")

public:
    explicit FileGuardService(QObject *parent = nullptr);

public Q_SLOTS:
    Q_SCRIPTABLE bool TrustFile(const QString &hash, const QString &path);
    Q_SCRIPTABLE bool RevokeFile(const QString &hash);
    Q_SCRIPTABLE bool IsTrusted(const QString &hash);

private:
    QString trustFilePath() const;
    bool reloadFapolicyd() const;
};

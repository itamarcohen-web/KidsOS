#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

// Bridges the KidsOS home screen to the rest of the system: launching real
// underlying applications, reading the profile written by onboarding, and
// persisting simple desktop preferences (currently just appearance mode).
class LauncherBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap profile READ profile CONSTANT)
    Q_PROPERTY(QString appearanceMode READ appearanceMode CONSTANT)

public:
    explicit LauncherBridge(QObject *parent = nullptr);

    QVariantMap profile() const;
    QString appearanceMode() const;

    // Starts a detached process for an installed app (e.g. a Flatpak app
    // ID or a plain binary name). Returns false if the command could not
    // be started (e.g. app not installed) so the UI can show a friendly
    // "not available" state instead of silently failing.
    Q_INVOKABLE bool launchCommand(const QString &command, const QStringList &args = {});

    // Persists "light" | "dark" | "system" so it survives a restart.
    Q_INVOKABLE void saveAppearanceMode(const QString &mode);

    // Locks this session and starts a fresh SDDM greeter (spec §11) —
    // selecting Parent there always requires real authentication; there
    // is no "already logged in" shortcut. See docs/ACCOUNTS_AND_LOGIN.md.
    Q_INVOKABLE bool switchUser();

    // App-request/approval backend (spec §15) — thin passthroughs to
    // org.kidsos.Installer1, exposed here so the Kids Store UI doesn't
    // need its own D-Bus wiring.
    Q_INVOKABLE QString submitInstallRequest(const QString &appId, const QString &appName,
                                              const QStringList &permissions);
    Q_INVOKABLE QVariantList myInstallRequests();

private:
    QVariantMap m_profile;
    QString m_appearanceMode = QStringLiteral("light");
};

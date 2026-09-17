#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>

// Bridges the KidsOS home screen to the rest of the system: launching real
// underlying applications, and reading the profile written by onboarding.
class LauncherBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap profile READ profile CONSTANT)

public:
    explicit LauncherBridge(QObject *parent = nullptr);

    QVariantMap profile() const;

    // Starts a detached process for an installed app (e.g. a Flatpak app
    // ID or a plain binary name). Returns false if the command could not
    // be started (e.g. app not installed) so the UI can show a friendly
    // "not available" state instead of silently failing.
    Q_INVOKABLE bool launchCommand(const QString &command, const QStringList &args = {});

private:
    QVariantMap m_profile;
};

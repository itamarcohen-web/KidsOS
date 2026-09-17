#pragma once

#include <QObject>
#include <QString>
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

private:
    QVariantMap m_profile;
    QString m_appearanceMode = QStringLiteral("light");
};

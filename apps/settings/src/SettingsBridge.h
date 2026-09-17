#pragma once

#include <QObject>
#include <QString>

// Persists desktop-wide preferences shared with the launcher (same
// ~/.config/kidsos/settings.json LauncherBridge reads/writes — see
// apps/launcher/src/LauncherBridge.cpp) so a change made in either place
// is picked up by the other on next launch.
class SettingsBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString appearanceMode READ appearanceMode CONSTANT)

public:
    explicit SettingsBridge(QObject *parent = nullptr);

    QString appearanceMode() const;
    Q_INVOKABLE void saveAppearanceMode(const QString &mode);

private:
    QString m_appearanceMode = QStringLiteral("light");
};

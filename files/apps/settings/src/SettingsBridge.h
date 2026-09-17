#pragma once

#include <QObject>
#include <QString>

// Persists desktop-wide preferences shared with the launcher (same
// ~/.config/kidsos/settings.json LauncherBridge reads/writes — see
// apps/launcher/src/LauncherBridge.cpp) so a change made in either place
// is picked up by the other on next launch. Also exposes whether the
// running account is a child (kidsos-children group membership) and
// queries org.kidsos.Policy1 for which settings the Parent has locked —
// spec §28.
class SettingsBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString appearanceMode READ appearanceMode CONSTANT)
    Q_PROPERTY(bool isChildAccount READ isChildAccount CONSTANT)

public:
    explicit SettingsBridge(QObject *parent = nullptr);

    QString appearanceMode() const;
    bool isChildAccount() const;

    Q_INVOKABLE void saveAppearanceMode(const QString &mode);
    Q_INVOKABLE bool isSettingManaged(const QString &settingId) const;

private:
    QString m_appearanceMode = QStringLiteral("light");
    bool m_isChildAccount = false;
};

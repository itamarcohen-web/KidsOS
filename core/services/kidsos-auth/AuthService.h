#pragma once

#include <QDBusMessage>
#include <QObject>
#include <QString>

// org.kidsos.Auth1 — account and session logic. Runs as root (systemd
// unit: recipes/files/usr/lib/systemd/system/kidsos-auth.service).
// See docs/SECURITY_ARCHITECTURE.md for the full contract, D-Bus policy,
// and polkit actions this implements.
class AuthService : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kidsos.Auth1")

public:
    explicit AuthService(QObject *parent = nullptr);

public Q_SLOTS:
    Q_SCRIPTABLE bool CreateParentAccount(const QString &name, const QString &username,
                                           const QString &password, const QDBusMessage &message);
    Q_SCRIPTABLE bool CreateChildAccount(const QString &name, const QString &username,
                                          const QString &pin, const QString &avatarId, int age,
                                          const QDBusMessage &message);
    Q_SCRIPTABLE bool ChangeChildPin(const QString &username, const QString &newPin,
                                      const QDBusMessage &message);
    Q_SCRIPTABLE bool SwitchToGreeter();
    Q_SCRIPTABLE bool MarkFirstBootComplete();

private:
    bool firstBootPending() const;
    bool callerIsSetupSession(const QDBusMessage &message) const;
    bool createLinuxAccount(const QString &username, const QString &comment,
                             const QString &secret, bool asAdmin) const;
    bool setLinuxSecret(const QString &username, const QString &secret) const;
    void writePublicProfile(const QString &username, const QString &displayName,
                             const QString &avatarId, const QString &role) const;
};

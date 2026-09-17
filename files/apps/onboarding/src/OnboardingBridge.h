#pragma once

#include <QObject>
#include <QString>

// Bridges the onboarding QML UI to org.kidsos.Auth1 over the system
// D-Bus (see docs/SECURITY_ARCHITECTURE.md, docs/ACCOUNTS_AND_LOGIN.md).
// This app runs as the unprivileged "kidsos-setup" user; every actual
// account-creation privilege lives in kidsos-auth, not here — this class
// does not itself touch useradd/chpasswd/shadow.
class OnboardingBridge : public QObject
{
    Q_OBJECT

public:
    explicit OnboardingBridge(QObject *parent = nullptr);

    Q_INVOKABLE bool createParentAccount(const QString &name, const QString &username,
                                          const QString &password);
    Q_INVOKABLE bool createChildAccount(const QString &name, const QString &username,
                                         const QString &pin, const QString &avatarId, int age);
    Q_INVOKABLE bool markFirstBootComplete();

    // Client-side sanity checks only (fast feedback while typing) — the
    // real validation happens again inside kidsos-auth, which never
    // trusts the caller.
    Q_INVOKABLE bool isValidUsername(const QString &username) const;
    Q_INVOKABLE QString suggestUsername(const QString &displayName) const;
};

#pragma once

#include <QObject>
#include <QString>

// Bridges the onboarding QML UI to the filesystem: persists the child's
// profile (name, avatar, age, language) and the child PIN.
//
// The PIN is never written in plaintext: it is combined with a random
// per-device salt and hashed with SHA-256 before it touches disk. This is
// the CHILD device PIN only — a separate, not-yet-implemented Parent PIN /
// parent-auth system will live behind its own bridge (see docs/ROADMAP.md).
class ProfileBridge : public QObject
{
    Q_OBJECT

public:
    explicit ProfileBridge(QObject *parent = nullptr);

    // Called from the Age/Avatar/Name screens as the child fills them in,
    // so a partial profile always exists even if setup is interrupted.
    Q_INVOKABLE void saveDraft(const QString &name, const QString &avatarId,
                                int age, const QString &language);

    // Hashes and stores the child PIN. Returns false on I/O failure.
    Q_INVOKABLE bool setChildPin(const QString &pin);

    // Verifies a PIN attempt against the stored hash (used by the lock
    // screen in a later milestone; exposed now so the contract is stable).
    Q_INVOKABLE bool verifyChildPin(const QString &pin) const;

    // Marks onboarding as complete so systemd starts the launcher instead
    // of the onboarding app on next session start (see recipes/recipe.yml).
    Q_INVOKABLE void completeOnboarding();

private:
    QString configDir() const;
};

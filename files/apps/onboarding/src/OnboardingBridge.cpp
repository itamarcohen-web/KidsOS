#include "OnboardingBridge.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QRegularExpression>

namespace {
QDBusInterface authInterface()
{
    return QDBusInterface(QStringLiteral("org.kidsos.Auth1"), QStringLiteral("/org/kidsos/Auth1"),
                           QStringLiteral("org.kidsos.Auth1"), QDBusConnection::systemBus());
}
}

OnboardingBridge::OnboardingBridge(QObject *parent) : QObject(parent) { }

bool OnboardingBridge::createParentAccount(const QString &name, const QString &username,
                                            const QString &password)
{
    QDBusInterface auth = authInterface();
    if (!auth.isValid())
        return false;
    QDBusReply<bool> reply = auth.call(QStringLiteral("CreateParentAccount"), name, username, password);
    return reply.isValid() && reply.value();
}

bool OnboardingBridge::createChildAccount(const QString &name, const QString &username,
                                           const QString &pin, const QString &avatarId, int age)
{
    QDBusInterface auth = authInterface();
    if (!auth.isValid())
        return false;
    QDBusReply<bool> reply =
        auth.call(QStringLiteral("CreateChildAccount"), name, username, pin, avatarId, age);
    return reply.isValid() && reply.value();
}

bool OnboardingBridge::markFirstBootComplete()
{
    QDBusInterface auth = authInterface();
    if (!auth.isValid())
        return false;
    QDBusReply<bool> reply = auth.call(QStringLiteral("MarkFirstBootComplete"));
    return reply.isValid() && reply.value();
}

bool OnboardingBridge::isValidUsername(const QString &username) const
{
    static const QRegularExpression pattern(QStringLiteral("^[a-z_][a-z0-9_-]{2,31}$"));
    return pattern.match(username).hasMatch();
}

QString OnboardingBridge::suggestUsername(const QString &displayName) const
{
    QString suggestion = displayName.toLower();
    suggestion.replace(QRegularExpression(QStringLiteral("[^a-z0-9]+")), QStringLiteral(""));
    if (suggestion.isEmpty() || !suggestion.at(0).isLetter())
        suggestion.prepend(QStringLiteral("user"));
    return suggestion.left(20);
}

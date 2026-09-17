#include "AuthService.h"
#include "../common/AuditLog.h"
#include "../common/PolkitCheck.h"

#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>

#include <pwd.h>
#include <unistd.h>

AuthService::AuthService(QObject *parent) : QObject(parent) { }

bool AuthService::firstBootPending() const
{
    return !QFile::exists(QStringLiteral("/var/lib/kidsos/firstboot-done"));
}

bool AuthService::callerIsSetupSession(const QDBusMessage &message) const
{
    QDBusReply<uint> uidReply = QDBusConnection::systemBus().interface()->serviceUid(message.service());
    if (!uidReply.isValid())
        return false;

    struct passwd *setupUser = getpwnam("kidsos-setup");
    if (!setupUser)
        return false;

    return uidReply.value() == setupUser->pw_uid;
}

bool AuthService::setLinuxSecret(const QString &username, const QString &secret) const
{
    // chpasswd reads "user:password" lines from stdin and hashes them
    // through the system's configured scheme (SHA-512 crypt via
    // libxcrypt on Fedora, per /etc/login.defs ENCRYPT_METHOD) — the
    // same real mechanism `passwd` itself uses. The secret never
    // touches argv or an environment variable (both are readable by
    // other processes on the system via /proc), only a private pipe.
    QProcess chpasswd;
    chpasswd.start(QStringLiteral("chpasswd"), {});
    if (!chpasswd.waitForStarted(3000))
        return false;

    chpasswd.write((username + QStringLiteral(":") + secret + QStringLiteral("\n")).toUtf8());
    chpasswd.closeWriteChannel();

    if (!chpasswd.waitForFinished(5000))
        return false;

    return chpasswd.exitStatus() == QProcess::NormalExit && chpasswd.exitCode() == 0;
}

bool AuthService::createLinuxAccount(const QString &username, const QString &comment,
                                      const QString &secret, bool asAdmin) const
{
    static const QRegularExpression validUsername(QStringLiteral("^[a-z_][a-z0-9_-]{0,31}$"));
    if (!validUsername.match(username).hasMatch())
        return false;

    QStringList args = { QStringLiteral("--create-home"), QStringLiteral("--shell"),
                          QStringLiteral("/bin/bash"), QStringLiteral("--comment"), comment };
    if (asAdmin) {
        args << QStringLiteral("--groups") << QStringLiteral("wheel");
    } else {
        args << QStringLiteral("--gid") << QStringLiteral("kidsos-children");
    }
    args << username;

    QProcess useradd;
    useradd.start(QStringLiteral("useradd"), args);
    if (!useradd.waitForFinished(5000) || useradd.exitCode() != 0)
        return false;

    return setLinuxSecret(username, secret);
}

void AuthService::writePublicProfile(const QString &username, const QString &displayName,
                                      const QString &avatarId, const QString &role) const
{
    // Consulted by the SDDM login theme (branding/sddm-theme/kidsos/) to
    // render account cards/avatars. Deliberately world-readable and
    // separate from ~/.config/kidsos/profile.json: the greeter runs as
    // the "sddm" system user, which cannot read another user's 0700
    // home directory — see docs/ACCOUNTS_AND_LOGIN.md. Contains no
    // secret material, only display metadata.
    QDir().mkpath(QStringLiteral("/var/lib/kidsos/profiles"));
    QJsonObject pub;
    pub["displayName"] = displayName;
    pub["avatarId"] = avatarId;
    pub["role"] = role;

    QFile file(QStringLiteral("/var/lib/kidsos/profiles/%1.json").arg(username));
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(QJsonDocument(pub).toJson(QJsonDocument::Compact));
        file.close();
        QFile::setPermissions(file.fileName(),
                               QFile::ReadOwner | QFile::WriteOwner | QFile::ReadGroup | QFile::ReadOther);
    }
}

bool AuthService::CreateParentAccount(const QString &name, const QString &username,
                                       const QString &password, const QDBusMessage &message)
{
    if (firstBootPending()) {
        if (!callerIsSetupSession(message))
            return false;
    } else if (!PolkitCheck::isAuthorized(message, QStringLiteral("org.kidsos.auth.create-account"))) {
        return false;
    }

    if (password.size() < 8)
        return false; // real administrative account — no short passwords

    const bool ok = createLinuxAccount(username, name, password, /*asAdmin=*/true);
    if (ok)
        writePublicProfile(username, name, QStringLiteral("parent"), QStringLiteral("parent"));
    AuditLog::record(QStringLiteral("parent.account_created"),
                      { { QStringLiteral("username"), username }, { QStringLiteral("ok"), ok } });
    return ok;
}

bool AuthService::CreateChildAccount(const QString &name, const QString &username,
                                      const QString &pin, const QString &avatarId, int age,
                                      const QDBusMessage &message)
{
    if (firstBootPending()) {
        if (!callerIsSetupSession(message))
            return false;
    } else if (!PolkitCheck::isAuthorized(message, QStringLiteral("org.kidsos.auth.create-account"))) {
        return false;
    }

    static const QRegularExpression pinPattern(QStringLiteral("^[0-9]{4,8}$"));
    if (!pinPattern.match(pin).hasMatch())
        return false;

    const bool created = createLinuxAccount(username, name, pin, /*asAdmin=*/false);
    if (!created) {
        AuditLog::record(QStringLiteral("child.account_created"),
                          { { QStringLiteral("username"), username }, { QStringLiteral("ok"), false } });
        return false;
    }

    // Seed the child's profile.json (read by LauncherBridge/SettingsBridge)
    // directly into their new home, then hand ownership to them.
    QJsonObject profile;
    profile["name"] = name;
    profile["avatarId"] = avatarId;
    profile["age"] = age;
    profile["language"] = QLocale::system().name().left(2);

    const QString homeConfig = QStringLiteral("/home/%1/.config/kidsos").arg(username);
    QDir().mkpath(homeConfig);
    QFile profileFile(homeConfig + QStringLiteral("/profile.json"));
    if (profileFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        profileFile.write(QJsonDocument(profile).toJson(QJsonDocument::Indented));
        profileFile.close();
    }
    QProcess::execute(QStringLiteral("chown"),
                       { QStringLiteral("-R"), username + QStringLiteral(":") + username,
                         QStringLiteral("/home/%1/.config").arg(username) });

    writePublicProfile(username, name, avatarId, QStringLiteral("child"));

    AuditLog::record(QStringLiteral("child.account_created"),
                      { { QStringLiteral("username"), username }, { QStringLiteral("ok"), true } });
    return true;
}

bool AuthService::ChangeChildPin(const QString &username, const QString &newPin,
                                  const QDBusMessage &message)
{
    if (!PolkitCheck::isAuthorized(message, QStringLiteral("org.kidsos.auth.manage-child")))
        return false;

    static const QRegularExpression pinPattern(QStringLiteral("^[0-9]{4,8}$"));
    if (!pinPattern.match(newPin).hasMatch())
        return false;

    const bool ok = setLinuxSecret(username, newPin);
    AuditLog::record(QStringLiteral("child.pin_changed"),
                      { { QStringLiteral("username"), username }, { QStringLiteral("ok"), ok } });
    return ok;
}

bool AuthService::SwitchToGreeter()
{
    // Standard freedesktop.org display-manager spec, implemented by
    // SDDM — not a KidsOS invention. See docs/ACCOUNTS_AND_LOGIN.md.
    QDBusMessage call = QDBusMessage::createMethodCall(
        QStringLiteral("org.freedesktop.DisplayManager"),
        QStringLiteral("/org/freedesktop/DisplayManager/Seat0"),
        QStringLiteral("org.freedesktop.DisplayManager.Seat"), QStringLiteral("SwitchToGreeter"));
    QDBusMessage reply = QDBusConnection::systemBus().call(call);
    return reply.type() == QDBusMessage::ReplyMessage;
}

bool AuthService::MarkFirstBootComplete()
{
    QDir().mkpath(QStringLiteral("/var/lib/kidsos"));
    QFile flag(QStringLiteral("/var/lib/kidsos/firstboot-done"));
    if (!flag.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    flag.close();

    // Disable the one-time kidsos-setup autologin now that real accounts
    // exist — see recipes/files/etc/sddm.conf.d/kidsos-setup-autologin.conf.
    QProcess::execute(QStringLiteral("rm"),
                       { QStringLiteral("-f"),
                         QStringLiteral("/etc/sddm.conf.d/kidsos-setup-autologin.conf") });

    AuditLog::record(QStringLiteral("firstboot.complete"));
    return true;
}

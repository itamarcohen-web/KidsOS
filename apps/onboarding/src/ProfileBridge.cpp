#include "ProfileBridge.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRandomGenerator>
#include <QStandardPaths>
#include <QTextStream>

ProfileBridge::ProfileBridge(QObject *parent) : QObject(parent) { }

QString ProfileBridge::configDir() const
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                          + QStringLiteral("/kidsos");
    QDir().mkpath(base);
    return base;
}

void ProfileBridge::saveDraft(const QString &name, const QString &avatarId, int age,
                               const QString &language)
{
    QJsonObject profile;
    profile["name"] = name;
    profile["avatarId"] = avatarId;
    profile["age"] = age;
    profile["language"] = language;

    QFile file(configDir() + QStringLiteral("/profile.json"));
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(QJsonDocument(profile).toJson(QJsonDocument::Indented));
        file.close();
    }
}

bool ProfileBridge::setChildPin(const QString &pin)
{
    // 128-bit random salt, hex-encoded.
    QByteArray salt;
    for (int i = 0; i < 16; ++i)
        salt.append(static_cast<char>(QRandomGenerator::global()->bounded(256)));

    const QByteArray hash = QCryptographicHash::hash(salt + pin.toUtf8(),
                                                       QCryptographicHash::Sha256);

    QJsonObject pinRecord;
    pinRecord["algorithm"] = "sha256";
    pinRecord["salt"] = QString::fromLatin1(salt.toHex());
    pinRecord["hash"] = QString::fromLatin1(hash.toHex());

    QFile file(configDir() + QStringLiteral("/child-pin.json"));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    file.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    file.write(QJsonDocument(pinRecord).toJson(QJsonDocument::Compact));
    file.close();
    return true;
}

bool ProfileBridge::verifyChildPin(const QString &pin) const
{
    QFile file(configDir() + QStringLiteral("/child-pin.json"));
    if (!file.open(QIODevice::ReadOnly))
        return false;

    const QJsonObject pinRecord = QJsonDocument::fromJson(file.readAll()).object();
    const QByteArray salt = QByteArray::fromHex(pinRecord["salt"].toString().toLatin1());
    const QByteArray expected = QByteArray::fromHex(pinRecord["hash"].toString().toLatin1());
    const QByteArray actual = QCryptographicHash::hash(salt + pin.toUtf8(),
                                                         QCryptographicHash::Sha256);
    return actual == expected;
}

void ProfileBridge::completeOnboarding()
{
    QFile flag(configDir() + QStringLiteral("/onboarding-complete"));
    if (flag.open(QIODevice::WriteOnly | QIODevice::Truncate))
        flag.close();
}

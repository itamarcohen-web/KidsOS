#include "ModelManager.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>

namespace ModelManager {

ModelManifest loadManifest(const QString &modelDir)
{
    ModelManifest manifest;

    QFile file(QDir(modelDir).filePath(QStringLiteral("model.json")));
    if (!file.open(QIODevice::ReadOnly))
        return manifest;

    const QJsonObject root = QJsonDocument::fromJson(file.readAll()).object();
    if (root.isEmpty())
        return manifest;

    manifest.name = root.value(QStringLiteral("name")).toString();
    manifest.version = root.value(QStringLiteral("version")).toString();
    manifest.dataFile = root.value(QStringLiteral("file")).toString();
    manifest.sha256 = root.value(QStringLiteral("sha256")).toString();
    manifest.license = root.value(QStringLiteral("license")).toString();
    manifest.approvalStatus = root.value(QStringLiteral("approvalStatus")).toString(QStringLiteral("UNREVIEWED"));
    manifest.valid = !manifest.name.isEmpty() && !manifest.dataFile.isEmpty();
    return manifest;
}

bool verifyIntegrity(const QString &modelDir, const ModelManifest &manifest)
{
    if (!manifest.valid || manifest.sha256.isEmpty())
        return false;

    QFile dataFile(QDir(modelDir).filePath(manifest.dataFile));
    if (!dataFile.open(QIODevice::ReadOnly))
        return false;

    QCryptographicHash hash(QCryptographicHash::Sha256);
    if (!hash.addData(&dataFile))
        return false;

    return QString::fromLatin1(hash.result().toHex()).compare(manifest.sha256, Qt::CaseInsensitive) == 0;
}

}

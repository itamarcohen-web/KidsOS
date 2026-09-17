#include "SettingsBridge.h"

#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

namespace {
QString configDir()
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                          + QStringLiteral("/kidsos");
    QDir().mkpath(base);
    return base;
}
}

SettingsBridge::SettingsBridge(QObject *parent) : QObject(parent)
{
    QFile file(configDir() + QStringLiteral("/settings.json"));
    if (file.open(QIODevice::ReadOnly)) {
        const QJsonObject obj = QJsonDocument::fromJson(file.readAll()).object();
        const QString mode = obj.value(QStringLiteral("appearanceMode")).toString();
        if (!mode.isEmpty())
            m_appearanceMode = mode;
    }
}

QString SettingsBridge::appearanceMode() const
{
    return m_appearanceMode;
}

void SettingsBridge::saveAppearanceMode(const QString &mode)
{
    m_appearanceMode = mode;

    QJsonObject settings;
    settings["appearanceMode"] = mode;

    QFile file(configDir() + QStringLiteral("/settings.json"));
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(QJsonDocument(settings).toJson(QJsonDocument::Indented));
        file.close();
    }
}

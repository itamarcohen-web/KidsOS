#include "SafetyPolicy.h"

#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>

namespace {
const QString kDefaultPath = QStringLiteral("/etc/kidsos/safety-policy.json");
}

SafetyPolicy::SafetyPolicy(const QString &path)
    : m_path(path.isEmpty() ? kDefaultPath : path)
{
}

bool SafetyPolicy::load()
{
    QFile file(m_path);
    if (!file.open(QIODevice::ReadOnly))
        return false; // missing file -> keep the conservative defaults above

    const QJsonObject root = QJsonDocument::fromJson(file.readAll()).object();
    m_safeThreshold = root.value(QStringLiteral("safeThreshold")).toDouble(m_safeThreshold);
    m_mediumThreshold = root.value(QStringLiteral("mediumThreshold")).toDouble(m_mediumThreshold);
    m_highThreshold = root.value(QStringLiteral("highThreshold")).toDouble(m_highThreshold);
    m_criticalThreshold = root.value(QStringLiteral("criticalThreshold")).toDouble(m_criticalThreshold);
    return true;
}

bool SafetyPolicy::save() const
{
    QJsonObject root;
    root[QStringLiteral("safeThreshold")] = m_safeThreshold;
    root[QStringLiteral("mediumThreshold")] = m_mediumThreshold;
    root[QStringLiteral("highThreshold")] = m_highThreshold;
    root[QStringLiteral("criticalThreshold")] = m_criticalThreshold;

    QFile file(m_path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    file.close();
    return QFile::setPermissions(m_path, QFile::ReadOwner | QFile::WriteOwner | QFile::ReadGroup);
}

void SafetyPolicy::setThreshold(const QString &name, double value)
{
    if (name == QStringLiteral("safeThreshold")) m_safeThreshold = value;
    else if (name == QStringLiteral("mediumThreshold")) m_mediumThreshold = value;
    else if (name == QStringLiteral("highThreshold")) m_highThreshold = value;
    else if (name == QStringLiteral("criticalThreshold")) m_criticalThreshold = value;
}

SafetyAi::Severity SafetyPolicy::severityForConfidence(double confidence) const
{
    if (confidence >= m_criticalThreshold) return SafetyAi::Severity::Critical;
    if (confidence >= m_highThreshold) return SafetyAi::Severity::High;
    if (confidence >= m_mediumThreshold) return SafetyAi::Severity::Medium;
    if (confidence >= m_safeThreshold) return SafetyAi::Severity::Low;
    return SafetyAi::Severity::Safe;
}

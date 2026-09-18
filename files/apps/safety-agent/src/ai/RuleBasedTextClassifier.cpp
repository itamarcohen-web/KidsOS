#include "RuleBasedTextClassifier.h"
#include "ModelManager.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

namespace {
const QString kDefaultModelDir = QStringLiteral("/usr/lib/kidsos/models/text-safety");
}

RuleBasedTextClassifier::RuleBasedTextClassifier() = default;

bool RuleBasedTextClassifier::load(const QString &modelDir)
{
    const QString dir = modelDir.isEmpty() ? kDefaultModelDir : modelDir;

    const ModelManifest manifest = ModelManager::loadManifest(dir);
    if (!manifest.valid || !ModelManager::verifyIntegrity(dir, manifest))
        return false;

    QFile dataFile(QDir(dir).filePath(manifest.dataFile));
    if (!dataFile.open(QIODevice::ReadOnly))
        return false;

    const QJsonObject root = QJsonDocument::fromJson(dataFile.readAll()).object();
    m_version = root.value(QStringLiteral("version")).toString(manifest.version);

    m_rules.clear();
    const QJsonArray rules = root.value(QStringLiteral("rules")).toArray();
    for (const QJsonValue &ruleValue : rules) {
        const QJsonObject ruleObj = ruleValue.toObject();
        Rule rule;
        rule.category = SafetyAi::categoryFromString(ruleObj.value(QStringLiteral("category")).toString());
        rule.weight = ruleObj.value(QStringLiteral("weight")).toDouble();
        for (const QJsonValue &pattern : ruleObj.value(QStringLiteral("patterns")).toArray()) {
            rule.patterns.append(QRegularExpression(
                pattern.toString(), QRegularExpression::CaseInsensitiveOption));
        }
        m_rules.append(rule);
    }

    m_loaded = !m_rules.isEmpty();
    return m_loaded;
}

SafetyAi::AnalysisResult RuleBasedTextClassifier::AnalyzeText(const QString &text, const QString &)
{
    SafetyAi::AnalysisResult result;
    result.modelVersion = m_version;
    if (!m_loaded || text.trimmed().isEmpty())
        return result; // Category::Unknown, Severity::Safe, confidence 0.0

    double bestWeight = 0.0;
    SafetyAi::Category bestCategory = SafetyAi::Category::Unknown;
    QString matchedPattern;

    for (const Rule &rule : m_rules) {
        for (const QRegularExpression &pattern : rule.patterns) {
            if (pattern.match(text).hasMatch() && rule.weight > bestWeight) {
                bestWeight = rule.weight;
                bestCategory = rule.category;
                matchedPattern = pattern.pattern();
            }
        }
    }

    result.category = bestCategory;
    result.confidence = bestWeight;
    if (bestWeight > 0.0) {
        result.explanation = QStringLiteral("On-screen text matched a %1 pattern from the local safety rule table.")
                                  .arg(SafetyAi::categoryToString(bestCategory));
    }
    return result;
}

SafetyAi::AnalysisResult RuleBasedTextClassifier::AnalyzeImage(const QImage &)
{
    return {}; // text-only classifier; SafetyAgent routes images through ILocalVisionEngine instead
}

SafetyAi::AnalysisResult RuleBasedTextClassifier::AnalyzeContext(const SafetyAi::AnalysisResult &current,
                                                                   const QVariantMap &)
{
    return current; // real sequence-awareness lives in ContextEngine, not here
}

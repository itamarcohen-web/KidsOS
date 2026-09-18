#pragma once

#include "ILocalAiEngine.h"

#include <QRegularExpression>
#include <QVector>

// Stage-1 (spec §7): a versioned keyword/pattern scorer, loaded from
// /usr/lib/kidsos/models/text-safety/ and integrity-checked by
// ModelManager before use. This is deliberately not a neural model —
// spec §54 asks for "small, efficient" for the first prototype, and a
// transparent rule table is exactly that; the pluggable-model
// architecture is where Stage-2 vision lives instead (see
// IVisionSafetyModel/ILocalVisionEngine).
class RuleBasedTextClassifier : public ILocalAiEngine
{
public:
    RuleBasedTextClassifier();

    // False if the model directory is missing or fails integrity
    // verification — callers should treat the classifier as
    // unavailable (fail safe: nothing gets escalated past Stage-1
    // without it) rather than fall back to a hard-coded rule set.
    bool load(const QString &modelDir = QString());

    SafetyAi::AnalysisResult AnalyzeText(const QString &text, const QString &language) override;
    SafetyAi::AnalysisResult AnalyzeImage(const QImage &image) override; // not applicable here
    SafetyAi::AnalysisResult AnalyzeContext(const SafetyAi::AnalysisResult &current,
                                             const QVariantMap &contextState) override; // passthrough; see ContextEngine
    QString modelVersion() const override { return m_version; }

    bool isLoaded() const { return m_loaded; }

private:
    struct Rule {
        SafetyAi::Category category;
        double weight;
        QVector<QRegularExpression> patterns;
    };

    QVector<Rule> m_rules;
    QString m_version;
    bool m_loaded = false;
};

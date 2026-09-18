#include "RiskEngine.h"

RiskEngine::RiskEngine(const SafetyPolicy &policy) : m_policy(policy) { }

SafetyAi::AnalysisResult RiskEngine::combine(const SafetyAi::AnalysisResult &textResult,
                                              const QVector<VisionClassificationResult> &visionResults) const
{
    SafetyAi::AnalysisResult best = textResult;

    for (const VisionClassificationResult &vision : visionResults) {
        if (!vision.available || vision.confidence <= best.confidence)
            continue;
        best.category = vision.category;
        best.confidence = vision.confidence;
        best.modelVersion = vision.modelVersion;
        best.explanation = QStringLiteral(
            "Local vision analysis (%1) flagged a %2 pattern with confidence %3.")
            .arg(vision.provider, SafetyAi::categoryToString(vision.category))
            .arg(vision.confidence, 0, 'f', 2);
    }

    // spec §29: SafetyPolicy's thresholds are the single source of
    // truth for confidence -> severity, applied here and nowhere else.
    best.severity = m_policy.severityForConfidence(best.confidence);
    return best;
}

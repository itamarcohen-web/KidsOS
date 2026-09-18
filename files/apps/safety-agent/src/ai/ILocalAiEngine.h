#pragma once

#include "../../../../core/services/common/safety/SafetyTypes.h"

#include <QImage>
#include <QString>
#include <QVariantMap>

// spec §8: the model-agnostic seam. Nothing in SafetyAgent/RiskEngine
// depends on *how* AnalyzeText/AnalyzeImage/AnalyzeContext are
// implemented, so a better text or context model can replace
// RuleBasedTextClassifier later without touching the pipeline around
// it. (Image analysis specifically goes through the separate
// IVisionSafetyModel/ILocalVisionEngine hierarchy in this milestone,
// per the modular vision architecture you specified — AnalyzeImage
// here exists so the interface matches spec §8 verbatim, but
// SafetyAgent calls ILocalVisionEngine directly for Stage-2.)
class ILocalAiEngine
{
public:
    virtual ~ILocalAiEngine() = default;

    virtual SafetyAi::AnalysisResult AnalyzeText(const QString &text, const QString &language) = 0;
    virtual SafetyAi::AnalysisResult AnalyzeImage(const QImage &image) = 0;

    // previousEvents: recent same-child AnalysisResults, oldest first —
    // this is what ContextEngine actually implements; a text/vision
    // engine may leave this as a passthrough.
    virtual SafetyAi::AnalysisResult AnalyzeContext(const SafetyAi::AnalysisResult &current,
                                                     const QVariantMap &contextState) = 0;

    virtual QString modelVersion() const = 0;
};

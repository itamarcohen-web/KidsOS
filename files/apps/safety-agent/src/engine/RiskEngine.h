#pragma once

#include "../../../../core/services/common/safety/SafetyPolicy.h"
#include "../../../../core/services/common/safety/SafetyTypes.h"
#include "../ai/IVisionSafetyModel.h"

#include <QVector>

// Combines Stage-1 text + Stage-2 vision (if available) + the Context
// Engine's adjustment into the final SafetyEvent fields (spec §13 last
// line: "This should be determined by the Risk Engine, not hardcoded
// into the vision classifier."; vision-clarification §14 says the same
// for vision results specifically). Thresholds always come from
// SafetyPolicy — never hardcoded here (spec §29).
class RiskEngine
{
public:
    explicit RiskEngine(const SafetyPolicy &policy);

    // textResult: Stage-1, already passed through ContextEngine::adjust.
    // visionResults: Stage-2, one entry per model that ran (may be empty
    // if vision analysis didn't run at all, e.g. Stage-1 was Safe).
    SafetyAi::AnalysisResult combine(const SafetyAi::AnalysisResult &textResult,
                                      const QVector<VisionClassificationResult> &visionResults) const;

private:
    const SafetyPolicy &m_policy;
};

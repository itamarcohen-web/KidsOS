#pragma once

#include "../../../core/services/common/safety/SafetyPolicy.h"
#include "ai/ILocalVisionEngine.h"
#include "app/IActiveApplicationProvider.h"
#include "capture/IScreenCaptureProvider.h"
#include "engine/ContextEngine.h"
#include "engine/RiskEngine.h"
#include "ocr/IOcrEngine.h"

#include <QString>
#include <memory>

class RuleBasedTextClassifier;

// Orchestrates one full sample of the pipeline described in
// docs/SAFETY_AI.md (spec §3/§30):
//
//   capture -> OCR -> Stage-1 text classifier -> [if Suspicious] ->
//   Stage-2 vision -> Context Engine -> Risk Engine -> report to
//   kidsos-safety over D-Bus (or discard, if the final result is Safe)
//
// Runs entirely inside kidsos-safety-agent, in the Child's own
// session — see docs/SAFETY_AI.md for why. One instance per process;
// SafetyScheduler calls runSample() once per interval.
class SafetyAgent
{
public:
    SafetyAgent(const QString &childId, const QString &locale);
    // Declared (not defaulted inline) because m_textClassifier is a
    // unique_ptr<RuleBasedTextClassifier> and that type is only
    // forward-declared here — an implicitly-generated destructor would
    // need it complete at every call site (including main.cpp, which
    // never includes RuleBasedTextClassifier.h), not just where
    // SafetyAgent.cpp actually defines it.
    ~SafetyAgent();

    // False if a hard prerequisite (e.g. no capture provider could be
    // constructed for this session type) is missing — the caller
    // should still keep running (a session-locked screen or a
    // momentary portal failure isn't fatal), just skip this sample.
    bool initialize();

    void runSample();

private:
    bool isSessionLocked() const;

    QString m_childId;
    QString m_locale;

    std::unique_ptr<IScreenCaptureProvider> m_capture;
    std::unique_ptr<IOcrEngine> m_ocr;
    std::unique_ptr<RuleBasedTextClassifier> m_textClassifier;
    std::unique_ptr<ILocalVisionEngine> m_visionEngine;
    std::unique_ptr<IActiveApplicationProvider> m_appProvider;

    SafetyPolicy m_policy;
    ContextEngine m_contextEngine;
    std::unique_ptr<RiskEngine> m_riskEngine;
};

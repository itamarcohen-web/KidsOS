#pragma once

#include "../../../../core/services/common/safety/SafetyTypes.h"

#include <QDateTime>
#include <QHash>
#include <QList>
#include <QString>

// spec §13/§14: a single sample never automatically becomes a serious
// incident. ContextEngine keeps a short rolling window of recent
// same-child samples (in memory only — this is a per-process, per-run
// window, not a persisted history) and adjusts the current sample's
// severity based on what came before it and what app it happened in.
//
// Two concrete behaviors from the spec, both implemented directly
// (not left as vague "context awareness"):
//   - Escalation: age question (LOW) -> +location (MEDIUM) ->
//     +secrecy request (HIGH), spec §13's worked example.
//   - De-escalation: a vision hit for Violence inside a known game
//     with no corroborating suspicious text stays LOW/informational
//     rather than HIGH, spec §14's worked example.
class ContextEngine
{
public:
    struct Sample {
        QDateTime timestamp;
        QString application;
        SafetyAi::Category category;
        double confidence;
    };

    explicit ContextEngine(int windowSize = 10, int windowMinutes = 15);

    // Call once per sample, after Stage-1/Stage-2 produce a raw
    // AnalysisResult, before RiskEngine turns it into a SafetyEvent.
    // Returns a (possibly) adjusted result; also records the sample
    // into this child's rolling window for future calls.
    SafetyAi::AnalysisResult adjust(const QString &childId, const QString &application,
                                     const SafetyAi::AnalysisResult &raw,
                                     bool applicationIsKnownGame);

private:
    void trimWindow(QList<Sample> &window) const;

    int m_windowSize;
    int m_windowMinutes;
    QHash<QString, QList<Sample>> m_windowsByChild;
};

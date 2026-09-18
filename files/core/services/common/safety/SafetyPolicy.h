#pragma once

#include "SafetyTypes.h"

// Centralizes the confidence thresholds that turn an AnalysisResult's
// raw confidence into a Severity (spec §29: "Do not hard-code
// thresholds into multiple modules"). Both kidsos-safety-agent's
// RiskEngine and kidsos-safety (for Parent-facing policy display) read
// the same file, so they can never disagree.
//
// Backed by /etc/kidsos/safety-policy.json (root:kidsos-service, 0640
// — same ownership pattern as kidsos-policy's policy.json). Only
// kidsos-safety writes it, gated by polkit like every other
// Parent-only setting; kidsos-safety-agent only ever reads it.
class SafetyPolicy
{
public:
    explicit SafetyPolicy(const QString &path = QString());

    bool load();
    bool save() const;

    double safeThreshold() const { return m_safeThreshold; }
    double mediumThreshold() const { return m_mediumThreshold; }
    double highThreshold() const { return m_highThreshold; }
    double criticalThreshold() const { return m_criticalThreshold; }

    void setThreshold(const QString &name, double value);

    // Maps a raw [0,1] confidence score to a Severity using the
    // thresholds above. Callers (RiskEngine) still apply Context
    // Engine adjustments on top of this baseline mapping.
    SafetyAi::Severity severityForConfidence(double confidence) const;

private:
    QString m_path;
    double m_safeThreshold = 0.35;
    double m_mediumThreshold = 0.55;
    double m_highThreshold = 0.75;
    double m_criticalThreshold = 0.90;
};

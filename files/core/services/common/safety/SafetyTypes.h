#pragma once

#include <QDateTime>
#include <QString>
#include <QVariantMap>

// Shared vocabulary for the KidsOS Local Safety AI System (Milestone 4).
// Both kidsos-safety-agent (runs in the Child's session, does the actual
// capture/OCR/AI work) and kidsos-safety (the privileged system service
// that owns the database) link against this header, so the two never
// drift on what a category/severity/event actually looks like — see
// docs/SAFETY_AI.md.
namespace SafetyAi {

// Neutral, descriptive categories (spec §16) — never a claim about a
// person's identity, only an observed pattern.
enum class Category {
    Cyberbullying,
    GroomingIndicators,
    SexualContent,
    SextortionIndicators,
    Violence,
    SelfHarm,
    Scam,
    Phishing,
    DangerousChallenge,
    PersonalInformationRequest,
    SecrecyRequest,
    Unknown,
};

enum class Severity {
    Safe,
    Low,
    Medium,
    High,
    Critical,
};

// spec §7: the two-stage gate. A sample that never leaves Safe is
// discarded without ever reaching the Context/Risk engines.
enum class StageVerdict {
    Safe,
    Suspicious,
};

QString categoryToString(Category category);
Category categoryFromString(const QString &value);
QString severityToString(Severity severity);
Severity severityFromString(const QString &value);

// spec §17: every AI result carries severity *and* confidence *and* a
// plain-language, evidence-based explanation — never a bare verdict.
struct AnalysisResult {
    Category category = Category::Unknown;
    Severity severity = Severity::Safe;
    double confidence = 0.0;
    QString explanation;
    QString modelVersion;
};

// spec §18: the structured, local-only record. Deliberately excludes
// anything resembling a password/PIN/auth secret — see
// docs/SAFETY_AI.md's "what we never store" section.
struct SafetyEvent {
    QString id;
    QDateTime timestamp;
    QString childId;
    QString application;
    Category category = Category::Unknown;
    Severity severity = Severity::Safe;
    double confidence = 0.0;
    QString summary;
    QString evidenceReference; // empty unless policy retained evidence (spec §19)
    QString captureQuality;    // "good" | "degraded" | "unavailable" (spec §15)
    QString aiModelVersion;
};

// spec §24: the schema a future KidsOS Parent website will eventually
// receive. Populated locally; never actually sent anywhere in this
// milestone (see ISafetyEventExporter / IParentSyncService).
QVariantMap toExportSchema(const SafetyEvent &event);

}

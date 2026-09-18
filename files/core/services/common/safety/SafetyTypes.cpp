#include "SafetyTypes.h"

namespace SafetyAi {

QString categoryToString(Category category)
{
    switch (category) {
    case Category::Cyberbullying: return QStringLiteral("CYBERBULLYING");
    case Category::GroomingIndicators: return QStringLiteral("GROOMING_INDICATORS");
    case Category::SexualContent: return QStringLiteral("SEXUAL_CONTENT");
    case Category::SextortionIndicators: return QStringLiteral("SEXTORTION_INDICATORS");
    case Category::Violence: return QStringLiteral("VIOLENCE");
    case Category::SelfHarm: return QStringLiteral("SELF_HARM");
    case Category::Scam: return QStringLiteral("SCAM");
    case Category::Phishing: return QStringLiteral("PHISHING");
    case Category::DangerousChallenge: return QStringLiteral("DANGEROUS_CHALLENGE");
    case Category::PersonalInformationRequest: return QStringLiteral("PERSONAL_INFORMATION_REQUEST");
    case Category::SecrecyRequest: return QStringLiteral("SECRECY_REQUEST");
    case Category::Unknown: break;
    }
    return QStringLiteral("UNKNOWN");
}

Category categoryFromString(const QString &value)
{
    if (value == QStringLiteral("CYBERBULLYING")) return Category::Cyberbullying;
    if (value == QStringLiteral("GROOMING_INDICATORS")) return Category::GroomingIndicators;
    if (value == QStringLiteral("SEXUAL_CONTENT")) return Category::SexualContent;
    if (value == QStringLiteral("SEXTORTION_INDICATORS")) return Category::SextortionIndicators;
    if (value == QStringLiteral("VIOLENCE")) return Category::Violence;
    if (value == QStringLiteral("SELF_HARM")) return Category::SelfHarm;
    if (value == QStringLiteral("SCAM")) return Category::Scam;
    if (value == QStringLiteral("PHISHING")) return Category::Phishing;
    if (value == QStringLiteral("DANGEROUS_CHALLENGE")) return Category::DangerousChallenge;
    if (value == QStringLiteral("PERSONAL_INFORMATION_REQUEST")) return Category::PersonalInformationRequest;
    if (value == QStringLiteral("SECRECY_REQUEST")) return Category::SecrecyRequest;
    return Category::Unknown;
}

QString severityToString(Severity severity)
{
    switch (severity) {
    case Severity::Safe: return QStringLiteral("SAFE");
    case Severity::Low: return QStringLiteral("LOW");
    case Severity::Medium: return QStringLiteral("MEDIUM");
    case Severity::High: return QStringLiteral("HIGH");
    case Severity::Critical: return QStringLiteral("CRITICAL");
    }
    return QStringLiteral("SAFE");
}

Severity severityFromString(const QString &value)
{
    if (value == QStringLiteral("LOW")) return Severity::Low;
    if (value == QStringLiteral("MEDIUM")) return Severity::Medium;
    if (value == QStringLiteral("HIGH")) return Severity::High;
    if (value == QStringLiteral("CRITICAL")) return Severity::Critical;
    return Severity::Safe;
}

QVariantMap toExportSchema(const SafetyEvent &event)
{
    return QVariantMap {
        { QStringLiteral("event_id"), event.id },
        { QStringLiteral("timestamp"), event.timestamp.toUTC().toString(Qt::ISODate) },
        { QStringLiteral("application"), event.application },
        { QStringLiteral("category"), categoryToString(event.category) },
        { QStringLiteral("severity"), severityToString(event.severity) },
        { QStringLiteral("confidence"), event.confidence },
        { QStringLiteral("summary"), event.summary },
        { QStringLiteral("evidence_reference"), event.evidenceReference },
        { QStringLiteral("model_version"), event.aiModelVersion },
    };
}

}

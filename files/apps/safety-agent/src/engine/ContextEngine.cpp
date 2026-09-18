#include "ContextEngine.h"

#include <algorithm>

ContextEngine::ContextEngine(int windowSize, int windowMinutes)
    : m_windowSize(windowSize), m_windowMinutes(windowMinutes)
{
}

void ContextEngine::trimWindow(QList<Sample> &window) const
{
    const QDateTime cutoff = QDateTime::currentDateTimeUtc().addSecs(-60 * m_windowMinutes);
    while (!window.isEmpty() && window.first().timestamp < cutoff)
        window.removeFirst();
    while (window.size() > m_windowSize)
        window.removeFirst();
}

SafetyAi::AnalysisResult ContextEngine::adjust(const QString &childId, const QString &application,
                                                const SafetyAi::AnalysisResult &raw,
                                                bool applicationIsKnownGame)
{
    QList<Sample> &window = m_windowsByChild[childId];
    trimWindow(window);

    SafetyAi::AnalysisResult adjusted = raw;

    if (raw.category == SafetyAi::Category::Unknown || raw.confidence <= 0.0) {
        // Nothing to adjust; still record a placeholder so repeated
        // truly-empty samples don't accidentally look like a gap in
        // the window for the checks below.
        window.append({ QDateTime::currentDateTimeUtc(), application, raw.category, raw.confidence });
        return adjusted;
    }

    const bool sawPersonalInfoBefore = std::any_of(window.cbegin(), window.cend(), [](const Sample &s) {
        return s.category == SafetyAi::Category::PersonalInformationRequest;
    });
    const int personalInfoCountBefore = std::count_if(window.cbegin(), window.cend(), [](const Sample &s) {
        return s.category == SafetyAi::Category::PersonalInformationRequest;
    });

    // spec §13 worked example: age question alone -> stays as Stage-1
    // scored it (LOW-ish). A *second* personal-information request in
    // the same window escalates towards MEDIUM. A secrecy request on
    // top of an established personal-information pattern escalates to
    // HIGH — the sequence is what matters, not any single message.
    if (raw.category == SafetyAi::Category::PersonalInformationRequest && personalInfoCountBefore >= 1) {
        adjusted.confidence = std::min(1.0, raw.confidence + 0.25);
        adjusted.explanation = QStringLiteral(
            "Repeated requests for personal information were detected across recent samples.");
    } else if (raw.category == SafetyAi::Category::SecrecyRequest && sawPersonalInfoBefore) {
        adjusted.confidence = std::max(raw.confidence, 0.85);
        adjusted.explanation = QStringLiteral(
            "A request to keep the conversation secret followed earlier requests for personal "
            "information — this combination is treated as a stronger indicator than either alone.");
        adjusted.category = SafetyAi::Category::GroomingIndicators;
    }

    // spec §14 worked example: violence flagged inside a known game,
    // with nothing else suspicious in the window, is de-escalated
    // rather than treated as a real-world safety incident.
    if (raw.category == SafetyAi::Category::Violence && applicationIsKnownGame) {
        const bool anyOtherSuspicious = std::any_of(window.cbegin(), window.cend(), [](const Sample &s) {
            return s.category != SafetyAi::Category::Violence && s.category != SafetyAi::Category::Unknown;
        });
        if (!anyOtherSuspicious) {
            adjusted.confidence = std::min(raw.confidence, 0.2);
            adjusted.explanation = QStringLiteral(
                "Violence-like imagery was detected inside a recognized game with no other "
                "suspicious activity, so this is recorded as informational only.");
        }
    }

    window.append({ QDateTime::currentDateTimeUtc(), application, raw.category, adjusted.confidence });
    return adjusted;
}

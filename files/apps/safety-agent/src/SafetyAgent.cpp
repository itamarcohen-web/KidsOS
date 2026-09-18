#include "SafetyAgent.h"

#include "ai/MockVisionEngine.h"
#include "ai/OnnxVisionEngine.h"
#include "ai/RuleBasedTextClassifier.h"
#include "app/ActiveApplicationProviders.h"
#include "capture/WaylandPortalCapture.h"
#include "capture/X11Capture.h"
#include "ocr/TesseractOcrEngine.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDebug>
#include <QProcessEnvironment>

namespace {

QString tesseractLanguageFor(const QString &locale)
{
    if (locale.startsWith(QStringLiteral("he"))) return QStringLiteral("heb");
    if (locale.startsWith(QStringLiteral("ar"))) return QStringLiteral("ara");
    return QStringLiteral("eng");
}

}

SafetyAgent::SafetyAgent(const QString &childId, const QString &locale)
    : m_childId(childId), m_locale(locale), m_contextEngine(10, 15)
{
}

// Defined here (not = default inline in the header) so it's
// instantiated in this translation unit, where RuleBasedTextClassifier
// (via "ai/RuleBasedTextClassifier.h" above) is a complete type.
SafetyAgent::~SafetyAgent() = default;

bool SafetyAgent::initialize()
{
    const QString sessionType = QProcessEnvironment::systemEnvironment().value(QStringLiteral("XDG_SESSION_TYPE"));
    if (sessionType == QStringLiteral("x11")) {
        m_capture = std::make_unique<X11Capture>();
        m_appProvider = std::make_unique<X11ActiveApplicationProvider>();
    } else {
        // Default to the Wayland path — Kinoite's default session is
        // Plasma/Wayland (see docs/KNOWN_LIMITATIONS.md).
        m_capture = std::make_unique<WaylandPortalCapture>();
        m_appProvider = std::make_unique<KWinActiveApplicationProvider>();
    }

    m_textClassifier = std::make_unique<RuleBasedTextClassifier>();
    if (!m_textClassifier->load()) {
        qWarning() << "kidsos-safety-agent: text-safety model failed to load or verify — "
                       "Stage-1 classification will report Unknown/Safe for every sample";
    }

    m_ocr = std::make_unique<TesseractOcrEngine>();

    // Mock is opt-in only (vision-clarification §26: "the production
    // image must clearly show that Vision Safety is not enabled unless
    // an approved model is installed") — a shipped image defaults to
    // OnnxVisionEngine, which honestly reports NOT_AVAILABLE until a
    // real model is approved and dropped in.
    if (QProcessEnvironment::systemEnvironment().value(QStringLiteral("KIDSOS_SAFETY_MOCK_VISION")) == QStringLiteral("1")) {
        m_visionEngine = std::make_unique<MockVisionEngine>();
    } else {
        auto onnx = std::make_unique<OnnxVisionEngine>();
        onnx->discoverModels();
        m_visionEngine = std::move(onnx);
    }

    m_policy.load();
    m_riskEngine = std::make_unique<RiskEngine>(m_policy);

    return true;
}

bool SafetyAgent::isSessionLocked() const
{
    QDBusInterface screenSaver(QStringLiteral("org.freedesktop.ScreenSaver"), QStringLiteral("/ScreenSaver"),
                                QStringLiteral("org.freedesktop.ScreenSaver"), QDBusConnection::sessionBus());
    if (!screenSaver.isValid())
        return false; // can't tell -> don't block sampling on an unrelated D-Bus hiccup

    const QDBusReply<bool> reply = screenSaver.call(QStringLiteral("GetActive"));
    return reply.isValid() && reply.value();
}

void SafetyAgent::runSample()
{
    QDBusInterface safetyService(QStringLiteral("org.kidsos.Safety1"), QStringLiteral("/org/kidsos/Safety1"),
                                  QStringLiteral("org.kidsos.Safety1"), QDBusConnection::systemBus());

    // spec §5: not while the computer is locked.
    if (isSessionLocked())
        return;

    const QImage frame = m_capture->captureActiveScreen();
    if (frame.isNull()) {
        // Capture failures must never crash the agent (spec §44) —
        // just skip this sample and try again next interval.
        return;
    }

    const IActiveApplicationProvider::Result app = m_appProvider->activeApplication();
    const QString appName = app.resolved ? app.applicationName : QString();
    const bool isGame = app.resolved && IActiveApplicationProvider::isKnownGame(appName);

    const OcrResult ocr = m_ocr->recognize(frame, tesseractLanguageFor(m_locale));

    SafetyAi::AnalysisResult stage1 = m_textClassifier->AnalyzeText(ocr.ok ? ocr.text : QString(), m_locale);

    // spec §7: Stage-1 gate. Below the Safe threshold, discard the
    // frame immediately without ever running Stage-2 vision on it.
    const bool suspicious = m_policy.severityForConfidence(stage1.confidence) != SafetyAi::Severity::Safe;

    QVector<VisionClassificationResult> visionResults;
    if (suspicious && m_visionEngine) {
        visionResults = m_visionEngine->AnalyzeImage(frame);
    }

    SafetyAi::AnalysisResult combined = suspicious
        ? m_riskEngine->combine(stage1, visionResults)
        : stage1;

    combined = m_contextEngine.adjust(m_childId, appName, combined, isGame);
    combined.severity = m_policy.severityForConfidence(combined.confidence);

    if (combined.severity == SafetyAi::Severity::Safe) {
        // spec §19: discard immediately, but still let the Safety
        // status indicator reflect that a check just happened.
        safetyService.call(QStringLiteral("Heartbeat"));
        return;
    }

    SafetyAi::SafetyEvent event;
    event.childId = m_childId;
    event.application = appName;
    event.category = combined.category;
    event.severity = combined.severity;
    event.confidence = combined.confidence;
    event.summary = combined.explanation;
    event.captureQuality = (ocr.ok && app.resolved) ? QStringLiteral("good") : QStringLiteral("degraded");
    event.aiModelVersion = combined.modelVersion.isEmpty() ? m_textClassifier->modelVersion() : combined.modelVersion;

    const QVariantMap exported = SafetyAi::toExportSchema(event);
    QVariantMap payload = exported;
    payload[QStringLiteral("childId")] = event.childId;
    payload[QStringLiteral("captureQuality")] = event.captureQuality;
    payload[QStringLiteral("modelVersion")] = event.aiModelVersion;

    safetyService.call(QStringLiteral("ReportEvent"), payload);
}

#include "MockVisionEngine.h"

#include <QBuffer>
#include <QCryptographicHash>

MockVisionEngine::MockVisionEngine()
{
    // Hashes of tests/fixtures/safety/images/*.png (regenerate both
    // sides together if those fixtures ever change — see
    // tests/validate_mock_vision_fixtures.py, which checks they still
    // match).
    m_fixtures.insert(QStringLiteral("a44fe89787da9c61198e63e6be1ba92d644b1ac17b58dda6f4960357f5568b83"),
                       { SafetyAi::Category::Violence, 0.92 });
    m_fixtures.insert(QStringLiteral("18059e0f1e204579a401faad2fb85dea3c932823ec0f936b3429359a2aa2c6de"),
                       { SafetyAi::Category::SexualContent, 0.88 });
    m_fixtures.insert(QStringLiteral("7c18e9c531d320073490069c62d96789f1fe8a5dca952c907b57350d9311d5f6"),
                       { SafetyAi::Category::SelfHarm, 0.81 });
    // synthetic_safe / synthetic_ambiguous_gameplay / synthetic_medical_educational
    // are intentionally absent: an unmatched image (including these)
    // means "Mock has no opinion", not "confirmed safe" — the false-positive
    // fixtures exist to prove the *Context Engine* is what keeps them
    // from escalating, not that the vision layer conveniently ignores them.
}

QVector<VisionClassificationResult> MockVisionEngine::AnalyzeImage(const QImage &image)
{
    QByteArray bytes;
    QBuffer buffer(&bytes);
    buffer.open(QIODevice::WriteOnly);
    image.save(&buffer, "PNG");

    const QString hash = QString::fromLatin1(
        QCryptographicHash::hash(bytes, QCryptographicHash::Sha256).toHex());

    VisionClassificationResult result;
    result.provider = QStringLiteral("mock");
    result.modelVersion = QStringLiteral("mock-vision-0.1");

    const auto it = m_fixtures.constFind(hash);
    if (it != m_fixtures.constEnd()) {
        result.category = it->category;
        result.confidence = it->confidence;
    } else {
        result.category = SafetyAi::Category::Unknown;
        result.confidence = 0.0;
    }
    return { result };
}

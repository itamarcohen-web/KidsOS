#pragma once

#include "ILocalVisionEngine.h"

#include <QHash>

// Development/test vision engine (vision-clarification §4/§5): matches
// an image's SHA-256 content hash against a fixed table built from the
// synthetic fixtures shipped in tests/fixtures/safety/images/ and
// returns deterministic, hardcoded results. Never inspects real pixel
// content — it is not a classifier, it is a stand-in so the rest of
// the pipeline (Context Engine, Risk Engine, SafetyEvent, storage) can
// be exercised end-to-end before a real production model exists.
//
// engineKind() always reports "Mock / Development" — every UI surface
// that shows vision status must echo that string verbatim rather than
// imply a real detection happened (spec §5 of the clarification: never
// display "AI detected violence" for a mock result).
class MockVisionEngine : public ILocalVisionEngine
{
public:
    MockVisionEngine();

    QVector<VisionClassificationResult> AnalyzeImage(const QImage &image) override;
    QString engineKind() const override { return QStringLiteral("Mock / Development"); }

private:
    struct FixtureResult {
        SafetyAi::Category category;
        double confidence;
    };
    QHash<QString, FixtureResult> m_fixtures; // sha256 hex -> result
};

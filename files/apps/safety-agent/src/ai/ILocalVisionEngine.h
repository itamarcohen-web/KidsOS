#pragma once

#include "IVisionSafetyModel.h"

#include <QVector>

// spec vision-clarification §2/§3: manages whichever
// IVisionSafetyModel providers are actually available and runs an
// image through all of them. The two providers this milestone ships —
// MockVisionEngine (deterministic, development-only) and
// OnnxVisionEngine (real inference, no model bundled) — are chosen at
// startup; a future FutureProductionVisionEngine slots in here without
// touching SafetyAgent/RiskEngine at all.
class ILocalVisionEngine
{
public:
    virtual ~ILocalVisionEngine() = default;

    // One result per registered category model. Models that have no
    // usable weights return {available: false} rather than being
    // omitted, so callers can distinguish "checked, safe" from "not
    // checked at all" (spec §12/§26).
    virtual QVector<VisionClassificationResult> AnalyzeImage(const QImage &image) = 0;

    // "Mock / Development" or "ONNX Runtime" — surfaced verbatim by
    // the dev diagnostic screen (spec §5/§20) so Mock output can never
    // be mistaken for production AI.
    virtual QString engineKind() const = 0;
};

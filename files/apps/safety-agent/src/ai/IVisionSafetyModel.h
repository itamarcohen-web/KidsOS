#pragma once

#include "../../../../core/services/common/safety/SafetyTypes.h"

#include <QImage>
#include <QString>
#include <QVariantMap>

// Per-category vision result (spec vision-clarification §10/§13): a
// classifier never collapses to a bare safe/unsafe bool, it always
// reports a confidence the Risk Engine can weigh against context.
struct VisionClassificationResult {
    SafetyAi::Category category = SafetyAi::Category::Unknown;
    double confidence = 0.0;
    QString modelVersion;
    QString provider; // e.g. "mock", "onnx:vision-safety-nsfw-0.1"
    bool available = true; // false = NOT_AVAILABLE (spec §12: never fake self-harm/etc.)
};

// One model = one narrow capability (spec §10/§11/§12: SexualContent,
// Violence, ISelfHarmVisionModel are each their own thing, not one
// monolithic "vision AI"). A single ILocalVisionEngine can hold
// several of these.
class IVisionSafetyModel
{
public:
    virtual ~IVisionSafetyModel() = default;

    virtual VisionClassificationResult AnalyzeImage(const QImage &image) = 0;
    virtual SafetyAi::Category GetCategory() const = 0;
    virtual QString GetModelVersion() const = 0;
    virtual QVariantMap GetModelMetadata() const = 0;
};

#pragma once

#include "ILocalVisionEngine.h"

#include <QVector>
#include <memory>

namespace Ort { class Env; class Session; }

// Real ONNX Runtime plumbing (vision-clarification §6/§9) — but ships
// with no model this milestone. Scans
// /usr/lib/kidsos/models/vision-safety/{nsfw,violence,general-safety}/
// for a model.json manifest + model.onnx; for each one that is present,
// integrity-verified (ModelManager), and marked
// APPROVED_FOR_DISTRIBUTION, loads an inference session. Anything
// missing, failing verification, or still UNREVIEWED/DEVELOPMENT_ONLY
// is skipped and reported NOT_AVAILABLE (spec §9/§26) — the rest of
// KidsOS keeps working either way.
//
// self-harm is intentionally never wired to a loadable session in this
// milestone regardless of what's on disk (vision-clarification §12):
// AnalyzeImage always reports NOT_AVAILABLE for Category::SelfHarm
// until a self-harm-specific model has actually been evaluated and
// approved.
//
// Preprocessing contract assumed for any model that IS loaded: single
// input tensor, NCHW float32, 224x224, values scaled to [0,1] — the
// common convention for image classifiers. This is a documented
// assumption (see docs/SAFETY_AI.md), not a verified one: no model
// ships this milestone to test it against.
class OnnxVisionEngine : public ILocalVisionEngine
{
public:
    OnnxVisionEngine();
    ~OnnxVisionEngine() override;

    // Scans the models directory; safe to call even if nothing is
    // found (rest of the engine falls back to NOT_AVAILABLE results).
    void discoverModels(const QString &modelsRootDir = QString());

    QVector<VisionClassificationResult> AnalyzeImage(const QImage &image) override;
    QString engineKind() const override { return QStringLiteral("ONNX Runtime"); }

private:
    struct LoadedModel {
        SafetyAi::Category category;
        QString version;
        std::shared_ptr<Ort::Session> session;
    };

    std::unique_ptr<Ort::Env> m_env;
    QVector<LoadedModel> m_models;
};

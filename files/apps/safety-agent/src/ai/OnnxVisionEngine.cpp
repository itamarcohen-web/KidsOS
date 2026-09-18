#include "OnnxVisionEngine.h"
#include "ModelManager.h"

#include <QDebug>
#include <QDir>
#include <QImage>

#include <onnxruntime_cxx_api.h>

namespace {

constexpr int kInputSize = 224;

struct CategoryDir {
    const char *dirName;
    SafetyAi::Category category;
};

// self-harm is deliberately excluded from this table — see
// OnnxVisionEngine.h. Only these two are ever candidates for loading
// in this milestone; "general-safety" is reserved for a future
// broader model and also not wired up yet.
constexpr CategoryDir kCategoryDirs[] = {
    { "nsfw", SafetyAi::Category::SexualContent },
    { "violence", SafetyAi::Category::Violence },
};

// NCHW float32, [0,1]-normalized 224x224 — see the documented
// preprocessing contract in OnnxVisionEngine.h.
std::vector<float> preprocess(const QImage &image)
{
    const QImage scaled = image.scaled(kInputSize, kInputSize, Qt::IgnoreAspectRatio, Qt::SmoothTransformation)
                               .convertToFormat(QImage::Format_RGB888);

    std::vector<float> tensor(3 * kInputSize * kInputSize);
    const int plane = kInputSize * kInputSize;
    for (int y = 0; y < kInputSize; ++y) {
        const uchar *line = scaled.constScanLine(y);
        for (int x = 0; x < kInputSize; ++x) {
            const int idx = y * kInputSize + x;
            tensor[0 * plane + idx] = line[x * 3 + 0] / 255.0f;
            tensor[1 * plane + idx] = line[x * 3 + 1] / 255.0f;
            tensor[2 * plane + idx] = line[x * 3 + 2] / 255.0f;
        }
    }
    return tensor;
}

}

OnnxVisionEngine::OnnxVisionEngine()
    : m_env(std::make_unique<Ort::Env>(ORT_LOGGING_LEVEL_WARNING, "kidsos-safety-agent"))
{
}

OnnxVisionEngine::~OnnxVisionEngine() = default;

void OnnxVisionEngine::discoverModels(const QString &modelsRootDir)
{
    const QString root = modelsRootDir.isEmpty()
        ? QStringLiteral("/usr/lib/kidsos/models/vision-safety")
        : modelsRootDir;

    for (const CategoryDir &entry : kCategoryDirs) {
        const QString modelDir = QDir(root).filePath(QString::fromLatin1(entry.dirName));

        const ModelManifest manifest = ModelManager::loadManifest(modelDir);
        if (!manifest.valid) {
            continue; // no manifest at all -> nothing shipped for this category
        }
        if (manifest.approvalStatus != QStringLiteral("APPROVED_FOR_DISTRIBUTION")) {
            qInfo() << "kidsos-safety-agent: vision model" << manifest.name
                    << "is" << manifest.approvalStatus << "- not loading (spec: only "
                       "APPROVED_FOR_DISTRIBUTION models may run in production)";
            continue;
        }
        if (!ModelManager::verifyIntegrity(modelDir, manifest)) {
            qWarning() << "kidsos-safety-agent: vision model" << manifest.name
                       << "failed integrity verification (MODEL_INTEGRITY_FAILURE) - not loading";
            continue;
        }

        const QString onnxPath = QDir(modelDir).filePath(manifest.dataFile);
        try {
            Ort::SessionOptions options;
            auto session = std::make_shared<Ort::Session>(*m_env, onnxPath.toUtf8().constData(), options);
            m_models.append({ entry.category, manifest.version, session });
            qInfo() << "kidsos-safety-agent: loaded vision model" << manifest.name << manifest.version;
        } catch (const Ort::Exception &e) {
            qWarning() << "kidsos-safety-agent: failed to load ONNX model" << onnxPath << ":" << e.what();
        }
    }
}

QVector<VisionClassificationResult> OnnxVisionEngine::AnalyzeImage(const QImage &image)
{
    QVector<VisionClassificationResult> results;

    // self-harm always reports NOT_AVAILABLE regardless of what's on
    // disk this milestone (vision-clarification §12).
    VisionClassificationResult selfHarm;
    selfHarm.category = SafetyAi::Category::SelfHarm;
    selfHarm.provider = QStringLiteral("onnx");
    selfHarm.available = false;
    results.append(selfHarm);

    if (m_models.isEmpty()) {
        for (const CategoryDir &entry : kCategoryDirs) {
            VisionClassificationResult unavailable;
            unavailable.category = entry.category;
            unavailable.provider = QStringLiteral("onnx");
            unavailable.available = false;
            results.append(unavailable);
        }
        return results;
    }

    const std::vector<float> inputTensor = preprocess(image);
    const std::array<int64_t, 4> inputShape = { 1, 3, kInputSize, kInputSize };

    Ort::MemoryInfo memoryInfo = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);

    for (const LoadedModel &model : m_models) {
        VisionClassificationResult result;
        result.category = model.category;
        result.modelVersion = model.version;
        result.provider = QStringLiteral("onnx");

        try {
            Ort::AllocatorWithDefaultOptions allocator;
            const auto inputName = model.session->GetInputNameAllocated(0, allocator);
            const auto outputName = model.session->GetOutputNameAllocated(0, allocator);
            const char *inputNames[] = { inputName.get() };
            const char *outputNames[] = { outputName.get() };

            Ort::Value inputValue = Ort::Value::CreateTensor<float>(
                memoryInfo, const_cast<float *>(inputTensor.data()), inputTensor.size(),
                inputShape.data(), inputShape.size());

            auto outputTensors = model.session->Run(Ort::RunOptions{ nullptr }, inputNames, &inputValue, 1,
                                                      outputNames, 1);

            // Expected contract: a single scalar or single-element
            // vector giving this category's positive-class probability.
            const float *outData = outputTensors.front().GetTensorData<float>();
            result.confidence = static_cast<double>(outData[0]);
            result.available = true;
        } catch (const Ort::Exception &e) {
            qWarning() << "kidsos-safety-agent: ONNX inference failed for category"
                       << SafetyAi::categoryToString(model.category) << ":" << e.what();
            result.available = false;
        }

        results.append(result);
    }

    return results;
}

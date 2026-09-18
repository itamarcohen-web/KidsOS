#pragma once

#include "IOcrEngine.h"

namespace tesseract { class TessBaseAPI; }

// Wraps Tesseract's C++ API (spec §10 — open source, has a stable API,
// ships trained data for eng/heb/ara). One TessBaseAPI instance is
// reused across samples and re-initialized only when the requested
// language changes, since Init() reloads trained data from disk and
// isn't cheap enough to call every 120 seconds regardless.
class TesseractOcrEngine : public IOcrEngine
{
public:
    TesseractOcrEngine();
    ~TesseractOcrEngine() override;

    OcrResult recognize(const QImage &image, const QString &languageHint) override;
    QString engineName() const override { return QStringLiteral("tesseract"); }

private:
    bool ensureInitialized(const QString &languageHint);

    tesseract::TessBaseAPI *m_api = nullptr;
    QString m_currentLanguage;
};

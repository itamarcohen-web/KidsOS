#include "TesseractOcrEngine.h"

#include <QDebug>

#include <tesseract/baseapi.h>

TesseractOcrEngine::TesseractOcrEngine() = default;

TesseractOcrEngine::~TesseractOcrEngine()
{
    if (m_api) {
        m_api->End();
        delete m_api;
    }
}

bool TesseractOcrEngine::ensureInitialized(const QString &languageHint)
{
    const QString language = languageHint.isEmpty() ? QStringLiteral("eng") : languageHint;
    if (m_api && m_currentLanguage == language)
        return true;

    if (m_api) {
        m_api->End();
        delete m_api;
        m_api = nullptr;
    }

    m_api = new tesseract::TessBaseAPI();
    // tessdata lives in the standard Fedora location installed by the
    // tesseract-langpack-* RPMs; nullptr lets tesseract use its
    // compiled-in default rather than hard-coding a path here.
    if (m_api->Init(nullptr, language.toUtf8().constData()) != 0) {
        qWarning() << "kidsos-safety-agent: tesseract init failed for language" << language;
        delete m_api;
        m_api = nullptr;
        return false;
    }

    m_currentLanguage = language;
    return true;
}

OcrResult TesseractOcrEngine::recognize(const QImage &image, const QString &languageHint)
{
    OcrResult result;
    if (image.isNull() || !ensureInitialized(languageHint))
        return result;

    // Tesseract wants raw scanline bytes; Grayscale8 is both a format
    // it accepts directly (1 byte/pixel) and generally improves
    // recognition over color input.
    const QImage grayscale = image.convertToFormat(QImage::Format_Grayscale8);
    m_api->SetImage(grayscale.constBits(), grayscale.width(), grayscale.height(),
                     1, static_cast<int>(grayscale.bytesPerLine()));

    char *text = m_api->GetUTF8Text();
    if (text) {
        result.text = QString::fromUtf8(text).trimmed();
        result.ok = true;
        delete[] text;
    }
    return result;
}

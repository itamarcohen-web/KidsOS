#pragma once

#include <QImage>
#include <QString>

// spec §11: OCR output is only ever an intermediate representation —
// text handed to the Stage-1 classifier, never itself a safety
// decision.
struct OcrResult {
    QString text;
    bool ok = false;
};

class IOcrEngine
{
public:
    virtual ~IOcrEngine() = default;

    // languageHint: "eng", "heb", or "ara" (spec §10) — chosen from the
    // Child's active KidsOS locale, same three languages the rest of
    // the system supports.
    virtual OcrResult recognize(const QImage &image, const QString &languageHint) = 0;

    virtual QString engineName() const = 0;
};

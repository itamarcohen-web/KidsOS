#include "FileClassifier.h"

#include <QFile>

#include <cstring>

QString FileClassifier::classify(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return QStringLiteral("unknown");

    const QByteArray head = file.read(64);
    file.close();

    if (head.size() < 4)
        return QStringLiteral("document");

    // ELF: 0x7f 'E' 'L' 'F'
    if (head.startsWith(QByteArrayLiteral("\x7f""ELF"))) {
        // AppImage type 1/2: ELF with 'A' 'I' <version> at offset 8.
        if (head.size() >= 11 && head.at(8) == 'A' && head.at(9) == 'I'
            && (head.at(10) == 0x01 || head.at(10) == 0x02)) {
            return QStringLiteral("appimage");
        }
        return QStringLiteral("elf");
    }

    // Shell/interpreter script: shebang line.
    if (head.startsWith(QByteArrayLiteral("#!")))
        return QStringLiteral("script");

    // .deb: ar archive ("!<arch>\n") — full confirmation would parse the
    // first archive member name ("debian-binary"), which the magic bytes
    // alone don't distinguish from a generic .a static library; treating
    // any ar archive as needing approval is the conservative choice.
    if (head.startsWith(QByteArrayLiteral("!<arch>\n")))
        return QStringLiteral("deb");

    // .rpm lead magic.
    static const unsigned char rpmMagic[4] = { 0xed, 0xab, 0xee, 0xdb };
    if (head.size() >= 4 && memcmp(head.constData(), rpmMagic, 4) == 0)
        return QStringLiteral("rpm");

    // Known document signatures are explicitly NOT gated (spec §21).
    if (head.startsWith(QByteArrayLiteral("%PDF")) // PDF
        || head.startsWith(QByteArrayLiteral("\xFF\xD8\xFF")) // JPEG
        || head.startsWith(QByteArrayLiteral("\x89PNG")) // PNG
        || head.startsWith(QByteArrayLiteral("PK\x03\x04"))) { // DOCX/ZIP-based formats
        return QStringLiteral("document");
    }

    // Plain text and anything else unrecognized: if it "looks like"
    // printable text, treat as a document; otherwise be conservative.
    bool looksLikeText = true;
    for (unsigned char c : head) {
        if (c == 0) { looksLikeText = false; break; }
    }
    return looksLikeText ? QStringLiteral("document") : QStringLiteral("unknown");
}

bool FileClassifier::requiresApproval(const QString &kind)
{
    return kind != QStringLiteral("document");
}

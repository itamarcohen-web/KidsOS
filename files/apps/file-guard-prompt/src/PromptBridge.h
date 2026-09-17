#pragma once

#include <QObject>
#include <QString>

// Bridges the "Parent approval required" dialog to
// org.kidsos.Installer1::SubmitExternalInstallRequest. This app is
// registered as the default handler for executable-ish MIME types (spec
// §17) — but note it is a *convenience*, not the enforcement: even if a
// child bypasses this dialog entirely (terminal, renamed file, ...),
// fapolicyd still blocks the actual exec() — see docs/TRUST_MODEL.md.
class PromptBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString fileName READ fileName CONSTANT)

public:
    explicit PromptBridge(const QString &filePath, QObject *parent = nullptr);

    QString fileName() const;
    Q_INVOKABLE bool submitRequest();

private:
    QString m_filePath;
};

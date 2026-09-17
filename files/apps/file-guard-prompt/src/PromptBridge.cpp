#include "PromptBridge.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QFileInfo>

PromptBridge::PromptBridge(const QString &filePath, QObject *parent)
    : QObject(parent), m_filePath(filePath)
{
}

QString PromptBridge::fileName() const
{
    return QFileInfo(m_filePath).fileName();
}

bool PromptBridge::submitRequest()
{
    QDBusInterface installer(QStringLiteral("org.kidsos.Installer1"),
                              QStringLiteral("/org/kidsos/Installer1"),
                              QStringLiteral("org.kidsos.Installer1"), QDBusConnection::systemBus());
    if (!installer.isValid())
        return false;

    // The child's own Linux username doubles as childId throughout the
    // request/approval data model — see docs/SECURITY_ARCHITECTURE.md.
    const QString childId = qEnvironmentVariable("USER");

    QDBusReply<QString> reply = installer.call(QStringLiteral("SubmitExternalInstallRequest"),
                                                childId, m_filePath, QString());
    return reply.isValid() && !reply.value().isEmpty();
}

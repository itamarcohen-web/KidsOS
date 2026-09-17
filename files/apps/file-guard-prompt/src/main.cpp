#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "PromptBridge.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("KidsOS App Guard"));
    app.setOrganizationName(QStringLiteral("KidsOS"));

    // Invoked as `kidsos-file-guard-prompt %f` from the .desktop MIME
    // handler entry (recipes/files/usr/share/applications/
    // org.kidsos.file-guard-prompt.desktop) — the file path is argv[1].
    const QString filePath = app.arguments().size() > 1 ? app.arguments().at(1) : QString();

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral(KIDSOS_QML_DIR));
    engine.rootContext()->setContextProperty(
        QStringLiteral("KidsOSLocalesPathOverride"),
        qEnvironmentVariable("KIDSOS_DEV_LOCALES_PATH"));

    PromptBridge bridge(filePath);
    engine.rootContext()->setContextProperty(QStringLiteral("Bridge"), &bridge);

    const QString mainQml = qEnvironmentVariableIsSet("KIDSOS_DEV_APP_QML_DIR")
        ? qEnvironmentVariable("KIDSOS_DEV_APP_QML_DIR") + QStringLiteral("/Main.qml")
        : QStringLiteral(KIDSOS_APP_QML_DIR "/Main.qml");

    engine.load(QUrl::fromLocalFile(mainQml));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}

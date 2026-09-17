#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>

#include "ApprovalsBridge.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("KidsOS Approvals"));
    app.setOrganizationName(QStringLiteral("KidsOS"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("kidsos-approvals")));

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(
        QStringLiteral("KidsOSLocalesPathOverride"),
        qEnvironmentVariable("KIDSOS_DEV_LOCALES_PATH"));

    // See apps/onboarding/src/main.cpp for the QML2_IMPORT_PATH note.
    engine.addImportPath(QStringLiteral(KIDSOS_QML_DIR));

    ApprovalsBridge bridge;
    engine.rootContext()->setContextProperty(QStringLiteral("Bridge"), &bridge);

    const QString mainQml = qEnvironmentVariableIsSet("KIDSOS_DEV_APP_QML_DIR")
        ? qEnvironmentVariable("KIDSOS_DEV_APP_QML_DIR") + QStringLiteral("/Main.qml")
        : QStringLiteral(KIDSOS_APP_QML_DIR "/Main.qml");

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    engine.load(QUrl::fromLocalFile(mainQml));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>

#include "OnboardingBridge.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("KidsOS Onboarding"));
    app.setOrganizationName(QStringLiteral("KidsOS"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("kidsos-onboarding")));

    QQmlApplicationEngine engine;

    // Shared KidsOS.Theme / KidsOS.Localization / KidsOS.Common modules,
    // installed under /usr/share/kidsos/qml/KidsOS/…. For local
    // development without installing, export QML2_IMPORT_PATH (a
    // colon-separated list Qt reads natively) to point at
    // branding/themes/qml, core/localization and apps/common/qml — see
    // docs/BUILD.md.
    engine.addImportPath(QStringLiteral(KIDSOS_QML_DIR));

    OnboardingBridge bridge;
    engine.rootContext()->setContextProperty(QStringLiteral("Bridge"), &bridge);
    engine.rootContext()->setContextProperty(
        QStringLiteral("KidsOSLocalesPathOverride"),
        qEnvironmentVariable("KIDSOS_DEV_LOCALES_PATH"));

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

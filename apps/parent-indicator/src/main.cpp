#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "IndicatorBridge.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("KidsOS Parent Mode"));
    app.setOrganizationName(QStringLiteral("KidsOS"));

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral(KIDSOS_QML_DIR));
    engine.rootContext()->setContextProperty(
        QStringLiteral("KidsOSLocalesPathOverride"),
        qEnvironmentVariable("KIDSOS_DEV_LOCALES_PATH"));

    IndicatorBridge bridge;
    engine.rootContext()->setContextProperty(QStringLiteral("Bridge"), &bridge);

    const QString mainQml = qEnvironmentVariableIsSet("KIDSOS_DEV_APP_QML_DIR")
        ? qEnvironmentVariable("KIDSOS_DEV_APP_QML_DIR") + QStringLiteral("/Main.qml")
        : QStringLiteral(KIDSOS_APP_QML_DIR "/Main.qml");

    engine.load(QUrl::fromLocalFile(mainQml));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}

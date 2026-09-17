#include "FilesBridge.h"

#include <QDir>
#include <QProcess>
#include <QStandardPaths>

FilesBridge::FilesBridge(QObject *parent) : QObject(parent) { }

bool FilesBridge::openLocation(const QString &location)
{
    QString path;

    if (location == QStringLiteral("home")) {
        path = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    } else if (location == QStringLiteral("documents")) {
        path = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    } else if (location == QStringLiteral("downloads")) {
        path = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    } else if (location == QStringLiteral("pictures")) {
        path = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    } else if (location == QStringLiteral("music")) {
        path = QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
    } else if (location == QStringLiteral("videos")) {
        path = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
    } else if (location == QStringLiteral("desktop")) {
        path = QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
    } else if (location == QStringLiteral("school")) {
        // Not a standard XDG directory — KidsOS-specific, created on
        // first use under the home directory.
        path = QStandardPaths::writableLocation(QStandardPaths::HomeLocation)
               + QStringLiteral("/School");
        QDir().mkpath(path);
    } else {
        return false;
    }

    if (path.isEmpty())
        return false;

    return QProcess::startDetached(QStringLiteral("dolphin"), { path });
}

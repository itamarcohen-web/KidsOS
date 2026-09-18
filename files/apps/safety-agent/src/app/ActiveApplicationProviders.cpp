#include "ActiveApplicationProviders.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDebug>
#include <QElapsedTimer>
#include <QThread>

#include <systemd/sd-journal.h>

#ifdef KIDSOS_HAVE_X11
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#endif

namespace {
const char *const kKnownGames[] = {
    "roblox", "minecraft", "steam", "discord", "fortniteclient",
    "steam_app_", "wine", "lutris", "heroic",
};
}

bool IActiveApplicationProvider::isKnownGame(const QString &applicationName)
{
    const QString lowered = applicationName.toLower();
    for (const char *needle : kKnownGames) {
        if (lowered.contains(QString::fromLatin1(needle)))
            return true;
    }
    return false;
}

IActiveApplicationProvider::Result KWinActiveApplicationProvider::activeApplication()
{
    Result result;

    QDBusInterface scripting(QStringLiteral("org.kde.KWin"), QStringLiteral("/Scripting"),
                              QStringLiteral("org.kde.kwin.Scripting"), QDBusConnection::sessionBus());
    if (!scripting.isValid())
        return result;

    const QDBusReply<int> scriptIdReply = scripting.call(
        QStringLiteral("loadScript"),
        QStringLiteral("/usr/share/kidsos/kwin-scripts/active-window.js"),
        QStringLiteral("kidsos-safety-active-window"));
    if (!scriptIdReply.isValid())
        return result;

    QDBusInterface script(QStringLiteral("org.kde.KWin"),
                           QStringLiteral("/Scripting/Script%1").arg(scriptIdReply.value()),
                           QStringLiteral("org.kde.kwin.Script"), QDBusConnection::sessionBus());
    if (!script.isValid())
        return result;

    // sd_journal_open must happen before run() so we don't race the
    // message being written.
    sd_journal *journal = nullptr;
    if (sd_journal_open(&journal, SD_JOURNAL_LOCAL_ONLY) < 0)
        return result;
    sd_journal_seek_tail(journal);
    sd_journal_previous(journal); // position just before "now"

    script.call(QStringLiteral("run"));

    QElapsedTimer timer;
    timer.start();
    const QString marker = QStringLiteral("KIDSOS_ACTIVE_WINDOW:");
    while (timer.elapsed() < 300) {
        const int rc = sd_journal_next(journal);
        if (rc <= 0) {
            QThread::msleep(20);
            continue;
        }
        const char *data = nullptr;
        size_t length = 0;
        if (sd_journal_get_data(journal, "MESSAGE", reinterpret_cast<const void **>(&data), &length) == 0) {
            const QString line = QString::fromUtf8(data, static_cast<int>(length));
            const int idx = line.indexOf(marker);
            if (idx >= 0) {
                result.applicationName = line.mid(idx + marker.length()).trimmed();
                result.resolved = !result.applicationName.isEmpty();
                break;
            }
        }
    }
    sd_journal_close(journal);

    return result;
}

IActiveApplicationProvider::Result X11ActiveApplicationProvider::activeApplication()
{
    Result result;

#ifdef KIDSOS_HAVE_X11
    Display *display = XOpenDisplay(nullptr);
    if (!display)
        return result;

    Window focused;
    int revertTo;
    XGetInputFocus(display, &focused, &revertTo);

    if (focused != None) {
        XClassHint classHint;
        if (XGetClassHint(display, focused, &classHint)) {
            if (classHint.res_class)
                result.applicationName = QString::fromLocal8Bit(classHint.res_class);
            result.resolved = !result.applicationName.isEmpty();
            if (classHint.res_name) XFree(classHint.res_name);
            if (classHint.res_class) XFree(classHint.res_class);
        }
    }

    XCloseDisplay(display);
#endif

    return result;
}

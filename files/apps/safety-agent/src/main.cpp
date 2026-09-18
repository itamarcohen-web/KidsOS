// kidsos-safety-agent: the Child-session half of the Local Safety AI
// System (Milestone 4, spec §1-55; see docs/SAFETY_AI.md). Started as
// a systemd --user unit (kidsos-safety-agent.service,
// WantedBy=graphical-session.target, globally enabled at image build
// time) for every logged-in user's session, since XDG portal screen
// capture must be requested from inside the session being captured —
// it exits immediately (success) if the logged-in account isn't in
// the kidsos-children group, exactly like
// files/system/usr/bin/kidsos-session-start's existing Parent/Child
// branch (spec §5: only the Child session is ever analyzed).
#include <QGuiApplication>
#include <QLocale>

#include "SafetyAgent.h"
#include "SafetyScheduler.h"

#include <grp.h>
#include <memory>
#include <pwd.h>
#include <unistd.h>

namespace {

bool currentUserIsChild()
{
    const passwd *pw = getpwuid(getuid());
    if (!pw)
        return false;

    const group *gr = getgrnam("kidsos-children");
    if (!gr)
        return false;
    if (pw->pw_gid == gr->gr_gid)
        return true;

    for (char **member = gr->gr_mem; member && *member; ++member) {
        if (QString::fromLocal8Bit(pw->pw_name) == QString::fromLocal8Bit(*member))
            return true;
    }
    return false;
}

constexpr int kCaptureIntervalSeconds = 120; // spec §4 default; see SafetyPolicy for the Parent-configurable form

}

int main(int argc, char *argv[])
{
    // QGuiApplication (not QCoreApplication) — X11Capture's
    // QScreen::grabWindow needs a platform plugin, even though this
    // process never shows a window.
    QGuiApplication app(argc, argv);

    if (!currentUserIsChild())
        return 0; // spec §5: not a Child session — nothing to do

    const passwd *pw = getpwuid(getuid());
    const QString childId = pw ? QString::fromLocal8Bit(pw->pw_name) : QStringLiteral("unknown");
    const QString locale = QLocale::system().name();

    auto agent = std::make_shared<SafetyAgent>(childId, locale);
    if (!agent->initialize())
        return 1;

    SafetyScheduler scheduler(kCaptureIntervalSeconds);
    scheduler.setCallback([&scheduler, agent]() {
        agent->runSample();
        scheduler.sampleFinished();
    });
    scheduler.start();

    return app.exec();
}

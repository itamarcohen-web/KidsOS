#include "X11Capture.h"

#include <QGuiApplication>
#include <QPixmap>
#include <QScreen>

QImage X11Capture::captureActiveScreen()
{
    QScreen *screen = QGuiApplication::primaryScreen();
    if (!screen)
        return {};

    // Whole virtual desktop, window id 0 — a headless QCoreApplication
    // agent has no window of its own to accidentally capture instead.
    const QPixmap pixmap = screen->grabWindow(0);
    return pixmap.toImage();
}

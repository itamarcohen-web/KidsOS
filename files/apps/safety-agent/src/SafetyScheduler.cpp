#include "SafetyScheduler.h"

#include <QTimer>

#include <time.h>

SafetyScheduler::SafetyScheduler(int intervalSeconds, QObject *parent)
    : QObject(parent), m_intervalMs(intervalSeconds * 1000)
{
    m_housekeepingTimer = new QTimer(this);
    m_housekeepingTimer->setInterval(1000);
    connect(m_housekeepingTimer, &QTimer::timeout, this, &SafetyScheduler::housekeepingTick);
}

qint64 SafetyScheduler::monotonicNowMs() const
{
    timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return static_cast<qint64>(ts.tv_sec) * 1000 + ts.tv_nsec / 1000000;
}

void SafetyScheduler::setCallback(std::function<void()> callback)
{
    m_callback = std::move(callback);
}

void SafetyScheduler::start()
{
    m_nextFireAtMs = monotonicNowMs() + m_intervalMs;
    m_housekeepingTimer->start();
}

void SafetyScheduler::stop()
{
    m_housekeepingTimer->stop();
}

void SafetyScheduler::housekeepingTick()
{
    if (m_busy)
        return; // spec §31: never let inference jobs accumulate

    const qint64 now = monotonicNowMs();
    if (now < m_nextFireAtMs)
        return;

    // Always computed from "now", never from the missed deadline —
    // this is what prevents a burst of catch-up samples after a long
    // suspend (spec §43).
    m_nextFireAtMs = now + m_intervalMs;

    if (m_callback) {
        m_busy = true;
        m_callback();
    }
}

void SafetyScheduler::sampleFinished()
{
    m_busy = false;
}

#pragma once

#include <QObject>
#include <functional>

// spec §31/§43: fires roughly every capture_interval_seconds (default
// 120, spec §4) while the session is unlocked, using CLOCK_MONOTONIC
// directly rather than trusting a single long-period QTimer to behave
// correctly across a suspend/resume cycle. A 1-second housekeeping
// QTimer just compares "now" to an explicit next-fire deadline; on
// resume from a long suspend, "now" jumps forward but the deadline
// computation always uses (now + interval) for the *next* deadline —
// never a backlog of missed past deadlines — so there is no burst of
// fake historical captures (spec §43's explicit requirement).
//
// Overlap prevention (spec §31): onTick will not be invoked again
// while a previous invocation hasn't called sampleFinished() yet.
class SafetyScheduler : public QObject
{
    Q_OBJECT

public:
    explicit SafetyScheduler(int intervalSeconds, QObject *parent = nullptr);

    // Called once per due interval, on the main thread. Must call
    // sampleFinished() when the sample+analysis pipeline completes
    // (synchronously or from a worker thread posting back).
    void setCallback(std::function<void()> callback);

    void start();
    void stop();

    // Caller invokes this when a triggered sample's full pipeline
    // (capture -> OCR -> AI -> ContextEngine -> RiskEngine -> report)
    // has finished, releasing the busy flag for the next tick.
    void sampleFinished();

private slots:
    void housekeepingTick();

private:
    qint64 monotonicNowMs() const;

    int m_intervalMs;
    qint64 m_nextFireAtMs = 0;
    bool m_busy = false;
    std::function<void()> m_callback;
    class QTimer *m_housekeepingTimer = nullptr;
};

#pragma once

#include <QObject>
#include <QString>

// Bridges Kids Files' location cards to the real filesystem: resolves
// each named location to a path and opens it in Dolphin. Kids Files is a
// branded front door, not a from-scratch file manager — see
// docs/ARCHITECTURE.md for why that scope was chosen.
class FilesBridge : public QObject
{
    Q_OBJECT

public:
    explicit FilesBridge(QObject *parent = nullptr);

    // location ∈ "home" | "school" | "documents" | "downloads" |
    // "pictures" | "music" | "videos" | "desktop". Returns false if the
    // location name isn't recognized or Dolphin couldn't be started.
    Q_INVOKABLE bool openLocation(const QString &location);
};

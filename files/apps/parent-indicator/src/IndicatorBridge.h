#pragma once

#include <QObject>

class IndicatorBridge : public QObject
{
    Q_OBJECT
public:
    explicit IndicatorBridge(QObject *parent = nullptr);
    Q_INVOKABLE bool switchUser();
};

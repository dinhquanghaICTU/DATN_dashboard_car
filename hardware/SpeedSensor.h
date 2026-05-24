#pragma once
#include <QObject>
#include <QTimer>
#include <pigpiod_if2.h>
#include <atomic>
#include <cstdint>
#include "AppConfig.h"

class SpeedSensor : public QObject {
    Q_OBJECT
    Q_PROPERTY(float rpm   READ rpm   NOTIFY dataUpdated)
    Q_PROPERTY(float speed READ speed NOTIFY dataUpdated)

public:
    explicit SpeedSensor(int piHandle, QObject* parent = nullptr);
    ~SpeedSensor();

    void onPulse(uint32_t tick);
    float rpm()   const { return m_rpm.load(); }
    float speed() const { return m_speed.load(); }

public slots:
    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

signals:
    void dataUpdated(float rpm, float speed);

private slots:
    void calculate();

private:
    int          pi;
    QTimer*      timer      = nullptr;
    std::atomic<int> pulseCount {0};
    std::atomic<uint32_t> lastPulseTick {0};
    std::atomic<uint32_t> lastEmitTick {0};
    std::atomic<float> m_rpm {0.0f};
    std::atomic<float> m_speed {0.0f};
};

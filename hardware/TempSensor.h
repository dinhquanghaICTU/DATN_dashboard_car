#pragma once
#include <QObject>
#include <QTimer>
#include <QDebug>
#include <pigpiod_if2.h>
#include "AppConfig.h"

class TempSensor : public QObject {
    Q_OBJECT
    Q_PROPERTY(float temperature READ temperature NOTIFY dataUpdated)

public:
    explicit TempSensor(int piHandle, QObject* parent = nullptr);
    ~TempSensor();

    float temperature() const { return m_temperature; }

public slots:
    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

signals:
    void dataUpdated(float temperature);

private slots:
    void readTemperature();

private:
    bool initMPU6050();

    int     pi;
    int     m_i2cHandle   = -1;
    QTimer* m_timer       = nullptr;
    float   m_temperature = 0.0f;

    static constexpr uint8_t PWR_MGMT_1 = 0x6B;
    static constexpr uint8_t TEMP_OUT_H = 0x41;
};

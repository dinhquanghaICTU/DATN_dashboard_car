#pragma once
#include <QObject>
#include <QTimer>
#include <QDebug>
#include <cstdint>
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
    bool initBMP280();
    bool openBMP280(uint8_t address);
    bool readCalibration();

    int     pi;
    int     m_i2cHandle   = -1;
    QTimer* m_timer       = nullptr;
    float   m_temperature = 0.0f;
    uint8_t m_address     = BMP280_I2C_ADDR;

    uint16_t m_digT1 = 0;
    int16_t  m_digT2 = 0;
    int16_t  m_digT3 = 0;

    static constexpr uint8_t CHIP_ID_REG   = 0xD0;
    static constexpr uint8_t CALIB_REG     = 0x88;
    static constexpr uint8_t CTRL_MEAS_REG = 0xF4;
    static constexpr uint8_t CONFIG_REG    = 0xF5;
    static constexpr uint8_t TEMP_MSB_REG  = 0xFA;
    static constexpr uint8_t BMP280_ID     = 0x58;
    static constexpr uint8_t BME280_ID     = 0x60;
};

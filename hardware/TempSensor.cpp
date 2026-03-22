#include "TempSensor.h"
#include <QThread>

TempSensor::TempSensor(int piHandle, QObject* parent)
    : QObject(parent), pi(piHandle) {}

TempSensor::~TempSensor() {
    stop();
    if (m_i2cHandle >= 0)
        i2c_close(pi, m_i2cHandle);
}

bool TempSensor::initMPU6050() {

    m_i2cHandle = i2c_open(pi, 1, MPU6050_I2C_ADDR, 0);
    if (m_i2cHandle < 0) {
        qDebug() << "[TempSensor] Cannot open I2C:" << m_i2cHandle;
        return false;
    }


    int result = i2c_write_byte_data(pi, m_i2cHandle, PWR_MGMT_1, 0x00);
    if (result < 0) {
        qDebug() << "[TempSensor] Cannot wake MPU6050:" << result;
        return false;
    }

    qDebug() << "[TempSensor] MPU6050 initialized!";
    return true;
}

void TempSensor::start() {
    if (!initMPU6050()) return;

    if (!m_timer) {
        m_timer = new QTimer(this);
        connect(m_timer, &QTimer::timeout,
                this, &TempSensor::readTemperature);
    }
    m_timer->start(TEMP_READ_INTERVAL_MS);
    qDebug() << "[TempSensor] Started";
}

void TempSensor::stop() {
    if (m_timer) m_timer->stop();
    qDebug() << "[TempSensor] Stopped";
}

void TempSensor::readTemperature() {

    int high = i2c_read_byte_data(pi, m_i2cHandle, TEMP_OUT_H);
    int low  = i2c_read_byte_data(pi, m_i2cHandle, TEMP_OUT_H + 1);

    if (high < 0 || low < 0) {
        qDebug() << "[TempSensor] Read error";
        return;
    }

    int16_t raw = (int16_t)((high << 8) | low);
    m_temperature = (raw / 340.0f) + 36.53f;

    qDebug() << "[TempSensor] Temperature:" << m_temperature << "°C";
        emit dataUpdated(m_temperature);
}

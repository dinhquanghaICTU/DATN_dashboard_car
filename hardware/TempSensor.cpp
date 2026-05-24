#include "TempSensor.h"
#include <QString>
#include <QThread>

namespace {
QString hexAddress(uint8_t address)
{
    return QStringLiteral("0x%1").arg(address, 2, 16, QLatin1Char('0'));
}
}

TempSensor::TempSensor(int piHandle, QObject* parent)
    : QObject(parent), pi(piHandle) {}

TempSensor::~TempSensor() {
    stop();
    if (m_i2cHandle >= 0)
        i2c_close(pi, m_i2cHandle);
}

bool TempSensor::openBMP280(uint8_t address) {
    m_i2cHandle = i2c_open(pi, BMP280_I2C_BUS, address, 0);
    if (m_i2cHandle < 0) {
        qDebug() << "[TempSensor] Cannot open BMP280 I2C address"
                 << hexAddress(address) << ":" << m_i2cHandle;
        return false;
    }

    int chipId = i2c_read_byte_data(pi, m_i2cHandle, CHIP_ID_REG);
    if (chipId < 0) {
        qDebug() << "[TempSensor] Cannot read BMP280 chip id at"
                 << hexAddress(address) << ":" << chipId;
        i2c_close(pi, m_i2cHandle);
        m_i2cHandle = -1;
        return false;
    }

    if (chipId != BMP280_ID && chipId != BME280_ID) {
        qDebug() << "[TempSensor] Wrong BMP280 chip id at"
                 << hexAddress(address) << ":"
                 << QStringLiteral("0x%1").arg(chipId, 2, 16, QLatin1Char('0'));
        i2c_close(pi, m_i2cHandle);
        m_i2cHandle = -1;
        return false;
    }

    m_address = address;
    return true;
}

bool TempSensor::readCalibration() {
    char calib[6] = {};
    int count = i2c_read_i2c_block_data(pi, m_i2cHandle, CALIB_REG, calib, sizeof(calib));
    if (count != static_cast<int>(sizeof(calib))) {
        qDebug() << "[TempSensor] Cannot read BMP280 calibration:" << count;
        return false;
    }

    auto u16le = [](char lsb, char msb) -> uint16_t {
        return static_cast<uint16_t>(
            static_cast<uint8_t>(lsb) | (static_cast<uint16_t>(static_cast<uint8_t>(msb)) << 8));
    };

    m_digT1 = u16le(calib[0], calib[1]);
    m_digT2 = static_cast<int16_t>(u16le(calib[2], calib[3]));
    m_digT3 = static_cast<int16_t>(u16le(calib[4], calib[5]));

    if (m_digT1 == 0 || m_digT2 == 0) {
        qDebug() << "[TempSensor] Invalid BMP280 calibration";
        return false;
    }

    return true;
}

bool TempSensor::initBMP280() {
    if (!openBMP280(BMP280_I2C_ADDR) && !openBMP280(BMP280_I2C_ADDR_ALT))
        return false;

    if (!readCalibration())
        return false;

    int config = i2c_write_byte_data(pi, m_i2cHandle, CONFIG_REG, 0xA0);
    if (config < 0) {
        qDebug() << "[TempSensor] Cannot configure BMP280:" << config;
        return false;
    }

    int ctrl = i2c_write_byte_data(pi, m_i2cHandle, CTRL_MEAS_REG, 0x23);
    if (ctrl < 0) {
        qDebug() << "[TempSensor] Cannot start BMP280 normal mode:" << ctrl;
        return false;
    }

    qDebug() << "[TempSensor] BMP280 initialized at address"
             << hexAddress(m_address);
    return true;
}

void TempSensor::start() {
    if (!initBMP280()) return;

    if (!m_timer) {
        m_timer = new QTimer(this);
        connect(m_timer, &QTimer::timeout,
                this, &TempSensor::readTemperature);
    }
    readTemperature();
    m_timer->start(TEMP_READ_INTERVAL_MS);
    qDebug() << "[TempSensor] Started";
}

void TempSensor::stop() {
    if (m_timer) m_timer->stop();
    qDebug() << "[TempSensor] Stopped";
}

void TempSensor::readTemperature() {
    char data[3] = {};
    int count = i2c_read_i2c_block_data(pi, m_i2cHandle, TEMP_MSB_REG, data, sizeof(data));
    if (count != static_cast<int>(sizeof(data))) {
        qDebug() << "[TempSensor] BMP280 temperature read error:" << count;
        return;
    }

    int32_t adcT = (static_cast<int32_t>(static_cast<uint8_t>(data[0])) << 12)
                 | (static_cast<int32_t>(static_cast<uint8_t>(data[1])) << 4)
                 | (static_cast<int32_t>(static_cast<uint8_t>(data[2])) >> 4);

    int32_t var1 = (((adcT >> 3) - (static_cast<int32_t>(m_digT1) << 1))
                  * static_cast<int32_t>(m_digT2)) >> 11;
    int32_t diff = (adcT >> 4) - static_cast<int32_t>(m_digT1);
    int32_t var2 = (((diff * diff) >> 12) * static_cast<int32_t>(m_digT3)) >> 14;
    int32_t tFine = var1 + var2;

    m_temperature = static_cast<float>((tFine * 5 + 128) >> 8) / 100.0f;
    qDebug() << "[TempSensor] Temperature:" << m_temperature << "°C";
    emit dataUpdated(m_temperature);
}

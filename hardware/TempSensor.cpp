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
        // qDebug() << "[TempSensor] Cannot open BMP280 I2C address"
        //          << hexAddress(address) << ":" << m_i2cHandle;
        return false;
    }

    int chipId = i2c_read_byte_data(pi, m_i2cHandle, CHIP_ID_REG);
    if (chipId < 0) {
        // qDebug() << "[TempSensor] Cannot read BMP280 chip id at"
        //          << hexAddress(address) << ":" << chipId;
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
    //ghép 2 byte 1 =>> số nguyên
    auto u16le = [](char lsb, char msb) -> uint16_t {
        return static_cast<uint16_t>(
            static_cast<uint8_t>(lsb) | (static_cast<uint16_t>(static_cast<uint8_t>(msb)) << 8));
    };
    //convert ra 16
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


        /*ghi vào thanh ghi này để config 
        
            t_sb	7–5	101	Thời gian chờ 1000 ms
            filter	4–2	000	Tắt bộ lọc IIR
            Reserved	1	0	Không sử dụng
            spi3w_en	0	0	Tắt SPI 3 dây
        
        */ 
    int config = i2c_write_byte_data(pi, m_i2cHandle, CONFIG_REG, 0xA0);
    if (config < 0) {
        qDebug() << "[TempSensor] Cannot configure BMP280:" << config;
        return false;
    }
        /*
        srs_t	7–5	001	Đo nhiệt độ oversampling ×1
        osrs_p	4–2	000	Bỏ qua đo áp suất
        mode	1–0	11	Normal mode
        
        */
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
    //khoi tao timmer
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

    //áp dụng công thức để bù độ chễ theo 

    /*
    Trong vật liệu bán dẫn,
     điện áp hoặc dòng điện trong mạch cảm biến thay đổi
    nhiệt độ	
    20°C	0,72 V
    25°C	0,70 V
    30°C	0,68 V

    ADC sẽ đo các mức điện áp này:
    0,72 V → mã ADC A
    0,70 V → mã ADC B
    0,68 V → mã ADC C
    
    */

    /*
        vd 

        data[0] = 0x7E
        data[1] = 0xED
        data[2] = 0x00

        dig_T1 = 27504
        dig_T2 = 26435
        dig_T3 = -1000

        adcT = (0x7E << 12)
        | (0xED << 4)
        | (0x00 >> 4);

        =>>adcT = 519888

        2. Tính var1
            519888 >> 3 = 64986
            27504 << 1  = 55008

            var1 = ((64986 - 55008) × 26435) >> 11
                = 128793
        3. Tính độ lệch diff
            diff = (519888 >> 4) - 27504;
            diff = 32493 - 27504
             = 4989
        4. Tính var2

        var2 = (((4989 × 4989) >> 12)
        × -1000) >> 14;
        var2 = -371
        tFine = var1 + var2;
        tFine = 128793 - 371
      = 128422


      temperature =
    ((128422 * 5 + 128) >> 8) / 100.0;
     = 25.08°C
    */
    int32_t adcT = (static_cast<int32_t>(static_cast<uint8_t>(data[0])) << 12)
                 | (static_cast<int32_t>(static_cast<uint8_t>(data[1])) << 4)
                 | (static_cast<int32_t>(static_cast<uint8_t>(data[2])) >> 4);

    int32_t var1 = (((adcT >> 3) - (static_cast<int32_t>(m_digT1) << 1))
                  * static_cast<int32_t>(m_digT2)) >> 11;
    int32_t diff = (adcT >> 4) - static_cast<int32_t>(m_digT1);
    int32_t var2 = (((diff * diff) >> 12) * static_cast<int32_t>(m_digT3)) >> 14;
    int32_t tFine = var1 + var2;

    m_temperature = static_cast<float>((tFine * 5 + 128) >> 8) / 100.0f;
    // m_temperature = 70;
    qDebug() << "Temperature:" << m_temperature << "°C";
    emit dataUpdated(m_temperature);
}

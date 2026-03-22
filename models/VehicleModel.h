#pragma once
#include <QObject>

class VehicleModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(float rpm         READ rpm         NOTIFY dataChanged)
    Q_PROPERTY(float speed       READ speed       NOTIFY dataChanged)
    Q_PROPERTY(float temperature READ temperature NOTIFY tempChanged)
    Q_PROPERTY(bool  bleConnected READ bleConnected NOTIFY bleChanged)

public:
    explicit VehicleModel(QObject* parent = nullptr) : QObject(parent) {}

    float rpm()          const { return m_rpm; }
    float speed()        const { return m_speed; }
    float temperature()  const { return m_temperature; }
    bool  bleConnected() const { return m_bleConnected; }

public slots:
    void onSensorData(float rpm, float speed) {
        m_rpm   = rpm;
        m_speed = speed;
        emit dataChanged();
    }

    void onTemperature(float temp) {
        m_temperature = temp;
        emit tempChanged();
    }

    void onBleConnected(bool connected) {
        m_bleConnected = connected;
        emit bleChanged();
    }

signals:
    void dataChanged();
    void tempChanged();
    void bleChanged();

private:
    float m_rpm          = 0.0f;
    float m_speed        = 0.0f;
    float m_temperature  = 0.0f;
    bool  m_bleConnected = false;
};

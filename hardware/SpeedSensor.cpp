#include "SpeedSensor.h"
#include <QDebug>
#include <QThread>

static SpeedSensor* g_instance = nullptr;

static void gpioCallback(int pi, unsigned gpio, unsigned level, uint32_t tick) {
    Q_UNUSED(pi) Q_UNUSED(gpio) Q_UNUSED(tick)
    if (level == 1 && g_instance)
        g_instance->onPulse();
}

SpeedSensor::SpeedSensor(int piHandle, QObject* parent)
    : QObject(parent), pi(piHandle)
{
    g_instance = this;
    set_mode(pi, PIN_SPEED_SENSOR, PI_INPUT);
    set_pull_up_down(pi, PIN_SPEED_SENSOR, PI_PUD_UP);
    callback(pi, PIN_SPEED_SENSOR, RISING_EDGE, gpioCallback);
}

SpeedSensor::~SpeedSensor() {
    stop();
    g_instance = nullptr;
}

void SpeedSensor::start() {
    if (!timer) {
        timer = new QTimer(this);
        connect(timer, &QTimer::timeout, this, &SpeedSensor::calculate);
    }
    pulseCount = 0;
    timer->start(SPEED_CALC_INTERVAL_MS);
    qDebug() << "[SpeedSensor] Started on thread:" << QThread::currentThreadId();
}

void SpeedSensor::stop() {
    if (timer) timer->stop();
    qDebug() << "[SpeedSensor] Stopped";
}

void SpeedSensor::onPulse() {
    pulseCount++;
}

void SpeedSensor::calculate() {
    int count  = pulseCount;
    pulseCount = 0;
    float intervalSec = SPEED_CALC_INTERVAL_MS / 1000.0f;
    m_rpm = (count / (float)LM393_HOLES_PER_REV) / intervalSec * 60.0f;
    const float WHEEL_CIRCUMFERENCE = 3.14159f * 0.065f;
    m_speed = (m_rpm / 60.0f) * WHEEL_CIRCUMFERENCE;
    qDebug() << "[SpeedSensor] RPM:" << m_rpm << "| Speed:" << m_speed;
    emit dataUpdated(m_rpm, m_speed);
}

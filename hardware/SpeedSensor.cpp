#include "SpeedSensor.h"
#include <QDebug>
#include <QThread>

static SpeedSensor* g_instance = nullptr;
static constexpr float WHEEL_CIRCUMFERENCE = 3.14159f * 0.065f;

static void gpioCallback(int pi, unsigned gpio, unsigned level, uint32_t tick) {
    Q_UNUSED(pi) Q_UNUSED(gpio)
    if (level == 1 && g_instance)
        g_instance->onPulse(tick);
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
        timer->setTimerType(Qt::PreciseTimer);
        connect(timer, &QTimer::timeout, this, &SpeedSensor::calculate);
    }
    pulseCount.store(0);
    lastPulseTick.store(0);
    lastEmitTick.store(0);
    timer->start(SPEED_CALC_INTERVAL_MS);
    qDebug() << "[SpeedSensor] Started on thread:" << QThread::currentThreadId();
}

void SpeedSensor::stop() {
    if (timer) timer->stop();
    qDebug() << "[SpeedSensor] Stopped";
}

void SpeedSensor::onPulse(uint32_t tick) {
    pulseCount.fetch_add(1, std::memory_order_relaxed);

    const uint32_t previousTick = lastPulseTick.exchange(tick, std::memory_order_relaxed);
    if (previousTick == 0) return;

    const uint32_t pulseDeltaUs = tick - previousTick;
    if (pulseDeltaUs < SPEED_MIN_PULSE_US) return;

    const float rpm = 60000000.0f / (pulseDeltaUs * (float)LM393_HOLES_PER_REV);
    const float speed = (rpm / 60.0f) * WHEEL_CIRCUMFERENCE * SPEED_REALISTIC_SCALE;
    m_rpm.store(rpm, std::memory_order_relaxed);
    m_speed.store(speed, std::memory_order_relaxed);

    const uint32_t previousEmitTick = lastEmitTick.load(std::memory_order_relaxed);
    if (previousEmitTick == 0 || tick - previousEmitTick >= SPEED_RENDER_INTERVAL_US) {
        lastEmitTick.store(tick, std::memory_order_relaxed);
        emit dataUpdated(rpm, speed);
    }
}

void SpeedSensor::calculate() {
    pulseCount.exchange(0, std::memory_order_relaxed);

    const uint32_t lastTick = lastPulseTick.load(std::memory_order_relaxed);
    if (lastTick == 0) return;

    const uint32_t now = get_current_tick(pi);
    
    // qDebug() << "[SpeedSensor] current rpm:"
    //          << m_rpm.load(std::memory_order_relaxed)
    //          << "speed m/s:"
    //          << m_speed.load(std::memory_order_relaxed);
    
    if (now - lastTick < SPEED_ZERO_TIMEOUT_MS * 1000U) return;
    if (m_rpm.load(std::memory_order_relaxed) == 0.0f &&
        m_speed.load(std::memory_order_relaxed) == 0.0f) return;

    m_rpm.store(0.0f, std::memory_order_relaxed);
    m_speed.store(0.0f, std::memory_order_relaxed);
    emit dataUpdated(0.0f, 0.0f);
}

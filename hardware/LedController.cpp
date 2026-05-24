#include "LedController.h"
#include <QDebug>

LedController::LedController(int piHandle, QObject* parent)
    : QObject(parent), pi(piHandle)
{
    init();
    connect(&m_blinkTimer, &QTimer::timeout, this, &LedController::onBlink);
    m_blinkTimer.setInterval(LIGHT_BLINK_INTERVAL_MS);
}

LedController::~LedController()
{
    allOff();
}

void LedController::init()
{
    set_mode(pi, PIN_LIGHT_LEFT, PI_OUTPUT);
    set_mode(pi, PIN_LIGHT_RIGHT, PI_OUTPUT);
    gpio_write(pi, PIN_LIGHT_LEFT, 0);
    gpio_write(pi, PIN_LIGHT_RIGHT, 0);
    qDebug() << "[LedController] Initialized on BCM pins"
             << PIN_LIGHT_LEFT << PIN_LIGHT_RIGHT;
}

void LedController::setLeftSignal(bool enabled)
{
    if (m_leftSignal == enabled && !m_rightSignal) return;
    m_leftSignal = enabled;
    if (enabled) m_rightSignal = false;
    m_blinkOn = enabled;
    updateOutputs();
    emit stateChanged();
}

void LedController::setRightSignal(bool enabled)
{
    if (m_rightSignal == enabled && !m_leftSignal) return;
    m_rightSignal = enabled;
    if (enabled) m_leftSignal = false;
    m_blinkOn = enabled;
    updateOutputs();
    emit stateChanged();
}

void LedController::setHazard(bool enabled)
{
    if (m_leftSignal == enabled && m_rightSignal == enabled) return;
    m_leftSignal = enabled;
    m_rightSignal = enabled;
    m_blinkOn = enabled;
    updateOutputs();
    emit stateChanged();
}

void LedController::setHeadLight(bool enabled)
{
    if (m_headLight == enabled) return;
    m_headLight = enabled;
    updateOutputs();
    emit stateChanged();
}

void LedController::toggleLeftSignal()
{
    setLeftSignal(!m_leftSignal || m_rightSignal);
}

void LedController::toggleRightSignal()
{
    setRightSignal(!m_rightSignal || m_leftSignal);
}

void LedController::toggleHazard()
{
    setHazard(!hazardEnabled());
}

void LedController::toggleHeadLight()
{
    setHeadLight(!m_headLight);
}

void LedController::allOff()
{
    m_leftSignal = false;
    m_rightSignal = false;
    m_headLight = false;
    m_blinkOn = false;
    m_blinkTimer.stop();
    gpio_write(pi, PIN_LIGHT_LEFT, 0);
    gpio_write(pi, PIN_LIGHT_RIGHT, 0);
    emit stateChanged();
}

void LedController::onBlink()
{
    m_blinkOn = !m_blinkOn;
    updateOutputs();
}

void LedController::updateOutputs()
{
    const bool blinking = m_leftSignal || m_rightSignal;
    if (blinking && !m_blinkTimer.isActive()) {
        m_blinkTimer.start();
    } else if (!blinking && m_blinkTimer.isActive()) {
        m_blinkTimer.stop();
        m_blinkOn = false;
    }

    const bool leftOn = m_leftSignal ? m_blinkOn : m_headLight;
    const bool rightOn = m_rightSignal ? m_blinkOn : m_headLight;

    gpio_write(pi, PIN_LIGHT_LEFT, leftOn ? 1 : 0);
    gpio_write(pi, PIN_LIGHT_RIGHT, rightOn ? 1 : 0);
}

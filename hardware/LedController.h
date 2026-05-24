#pragma once

#include <QObject>
#include <QTimer>
#include <pigpiod_if2.h>
#include "AppConfig.h"

class LedController : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool leftSignal READ leftSignal NOTIFY stateChanged)
    Q_PROPERTY(bool rightSignal READ rightSignal NOTIFY stateChanged)
    Q_PROPERTY(bool headLight READ headLight NOTIFY stateChanged)

public:
    explicit LedController(int piHandle, QObject* parent = nullptr);
    ~LedController() override;

    bool leftSignal() const { return m_leftSignal; }
    bool rightSignal() const { return m_rightSignal; }
    bool headLight() const { return m_headLight; }

public slots:
    Q_INVOKABLE void setLeftSignal(bool enabled);
    Q_INVOKABLE void setRightSignal(bool enabled);
    Q_INVOKABLE void setHazard(bool enabled);
    Q_INVOKABLE void setHeadLight(bool enabled);
    Q_INVOKABLE void toggleLeftSignal();
    Q_INVOKABLE void toggleRightSignal();
    Q_INVOKABLE void toggleHazard();
    Q_INVOKABLE void toggleHeadLight();
    Q_INVOKABLE void allOff();

signals:
    void stateChanged();

private slots:
    void onBlink();

private:
    void init();
    void updateOutputs();
    bool hazardEnabled() const { return m_leftSignal && m_rightSignal; }

    int pi;
    bool m_leftSignal = false;
    bool m_rightSignal = false;
    bool m_headLight = false;
    bool m_blinkOn = false;
    QTimer m_blinkTimer;
};

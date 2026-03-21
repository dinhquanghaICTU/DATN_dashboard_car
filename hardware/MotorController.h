#pragma once
#include <QObject>
#include <pigpiod_if2.h>
#include "AppConfig.h"

class MotorController : public QObject {
    Q_OBJECT
    Q_PROPERTY(int speed READ speed WRITE setSpeed NOTIFY speedChanged)

public:
    enum Direction { Forward, Backward, Stop };

    explicit MotorController(int piHandle, QObject* parent = nullptr);
    ~MotorController();

    void init();
    int speed() const { return m_speed; }

public slots:
    void forward(int speed = MOTOR_DEFAULT_SPEED);
    void backward(int speed = MOTOR_DEFAULT_SPEED);
    void turnLeft(int speed = MOTOR_DEFAULT_SPEED);
    void turnRight(int speed = MOTOR_DEFAULT_SPEED);
    void rotateLeft(int speed = MOTOR_DEFAULT_SPEED);   // quay tại chỗ
    void rotateRight(int speed = MOTOR_DEFAULT_SPEED);  // quay tại chỗ
    void stop();
    void setSpeed(int speed);

signals:
    void speedChanged(int speed);

private:
    void setLeft(Direction dir, int speed);
    void setRight(Direction dir, int speed);
    int  calcDuty(int percent);

    int pi;
    int m_speed = 0;
};

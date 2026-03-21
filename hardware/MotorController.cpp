#include "MotorController.h"
#include <QDebug>

MotorController::MotorController(int piHandle, QObject* parent)
    : QObject(parent), pi(piHandle)
{
    init();
}

MotorController::~MotorController() {
    stop();
}

void MotorController::init() {
    // Setup chân IN — L298N trái
    set_mode(pi, PIN_MOTOR_IN1, PI_OUTPUT);
    set_mode(pi, PIN_MOTOR_IN2, PI_OUTPUT);

    // Setup chân IN — L298N phải
    set_mode(pi, PIN_MOTOR_IN3, PI_OUTPUT);
    set_mode(pi, PIN_MOTOR_IN4, PI_OUTPUT);

    // Tắt hết trước
    gpio_write(pi, PIN_MOTOR_IN1, 0);
    gpio_write(pi, PIN_MOTOR_IN2, 0);
    gpio_write(pi, PIN_MOTOR_IN3, 0);
    gpio_write(pi, PIN_MOTOR_IN4, 0);

    // PWM cho 2 bên — hardware PWM
    hardware_PWM(pi, PIN_MOTOR_ENA, MOTOR_PWM_FREQ, 0);
    hardware_PWM(pi, PIN_MOTOR_ENB, MOTOR_PWM_FREQ, 0);

    qDebug() << "[MotorController] Initialized — Tank mode";
}

void MotorController::forward(int speed) {
    qDebug() << "[Motor] FORWARD speed:" << speed;
    setLeft(Forward, speed);
    setRight(Forward, speed);
    m_speed = speed;
    emit speedChanged(m_speed);
}

void MotorController::backward(int speed) {
    qDebug() << "[Motor] BACKWARD speed:" << speed;
    setLeft(Backward, speed);
    setRight(Backward, speed);
    m_speed = speed;
    emit speedChanged(m_speed);
}

void MotorController::turnLeft(int speed) {
    qDebug() << "[Motor] TURN LEFT speed:" << speed;
    setLeft(Forward, speed / 2);
    setRight(Forward, speed);
}

void MotorController::turnRight(int speed) {
    qDebug() << "[Motor] TURN RIGHT speed:" << speed;
    setLeft(Forward, speed);
    setRight(Forward, speed / 2);
}

void MotorController::rotateLeft(int speed) {
    // Quay tại chỗ: 2 bên ngược chiều nhau
    qDebug() << "[Motor] ROTATE LEFT speed:" << speed;
    setLeft(Backward, speed);
    setRight(Forward, speed);
}

void MotorController::rotateRight(int speed) {
    qDebug() << "[Motor] ROTATE RIGHT speed:" << speed;
    setLeft(Forward, speed);
    setRight(Backward, speed);
}

void MotorController::stop() {
    qDebug() << "[Motor] STOP";
    setLeft(Stop, 0);
    setRight(Stop, 0);
    m_speed = 0;
    emit speedChanged(0);
}

void MotorController::setSpeed(int speed) {
    m_speed = qBound(0, speed, 100);
    hardware_PWM(pi, PIN_MOTOR_ENA, MOTOR_PWM_FREQ, calcDuty(m_speed));
    hardware_PWM(pi, PIN_MOTOR_ENB, MOTOR_PWM_FREQ, calcDuty(m_speed));
    emit speedChanged(m_speed);
}


void MotorController::setLeft(Direction dir, int speed) {
    switch (dir) {
    case Forward:
        gpio_write(pi, PIN_MOTOR_IN1, 0);
        gpio_write(pi, PIN_MOTOR_IN2, 1);
        break;
    case Backward:
        gpio_write(pi, PIN_MOTOR_IN1, 1);
        gpio_write(pi, PIN_MOTOR_IN2, 0);
        break;
    case Stop:
        gpio_write(pi, PIN_MOTOR_IN1, 0);
        gpio_write(pi, PIN_MOTOR_IN2, 0);
        break;
    }
    hardware_PWM(pi, PIN_MOTOR_ENA, MOTOR_PWM_FREQ, calcDuty(speed));
}

void MotorController::setRight(Direction dir, int speed) {
    switch (dir) {
    case Forward:
        gpio_write(pi, PIN_MOTOR_IN3, 1);
        gpio_write(pi, PIN_MOTOR_IN4, 0);
        break;
    case Backward:
        gpio_write(pi, PIN_MOTOR_IN3, 0);
        gpio_write(pi, PIN_MOTOR_IN4, 1);
        break;
    case Stop:
        gpio_write(pi, PIN_MOTOR_IN3, 0);
        gpio_write(pi, PIN_MOTOR_IN4, 0);
        break;
    }
    hardware_PWM(pi, PIN_MOTOR_ENB, MOTOR_PWM_FREQ, calcDuty(speed));
}

int MotorController::calcDuty(int percent) {

    return qBound(0, percent, 100) * 10000;
}

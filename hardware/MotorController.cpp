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
    
    set_mode(pi, PIN_MOTOR_IN1, PI_OUTPUT);
    set_mode(pi, PIN_MOTOR_IN2, PI_OUTPUT);

    
    set_mode(pi, PIN_MOTOR_IN3, PI_OUTPUT);
    set_mode(pi, PIN_MOTOR_IN4, PI_OUTPUT);

    
    gpio_write(pi, PIN_MOTOR_IN1, 0);
    gpio_write(pi, PIN_MOTOR_IN2, 0);
    gpio_write(pi, PIN_MOTOR_IN3, 0);
    gpio_write(pi, PIN_MOTOR_IN4, 0);

    
    hardware_PWM(pi, PIN_MOTOR_ENA, MOTOR_PWM_FREQ, 0);
    hardware_PWM(pi, PIN_MOTOR_ENB, MOTOR_PWM_FREQ, 0);

    qDebug() << "init done";
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
    qDebug() << "[Motor] TURN LEFT (Quay Trái) speed:" << speed;
    rotateLeft(speed);
    m_speed = speed;
    emit speedChanged(m_speed);
}

void MotorController::turnRight(int speed) {
    qDebug() << "[Motor] TURN RIGHT (Quay Phải) speed:" << speed;
    rotateRight(speed);
    m_speed = speed;
    emit speedChanged(m_speed);
}

void MotorController::rotateLeft(int speed) {
    // Quay tại chỗ sang TRÁI: Bánh trái lùi, Bánh phải tiến
    qDebug() << "[Motor] ROTATE LEFT speed:" << speed;
    setLeft(Backward, speed);
    setRight(Forward, speed);
}

void MotorController::rotateRight(int speed) {
    // Quay tại chỗ sang PHẢI: Bánh trái tiến, Bánh phải lùi
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
    int in1 = 0;
    int in2 = 0;

    switch (dir) {
    case Forward:
        in1 = 1;
        in2 = 0;
        break;
    case Backward:
        in1 = 0;
        in2 = 1;
        break;
    case Stop:
        in1 = 0;
        in2 = 0;
        break;
    }
    gpio_write(pi, PIN_MOTOR_IN1, in1);
    gpio_write(pi, PIN_MOTOR_IN2, in2);

    const int trimmedSpeed = applyTrim(speed, MOTOR_LEFT_TRIM_PERCENT);
    qDebug() << "[Motor] LEFT: pin" << PIN_MOTOR_IN1 << "=" << in1
             << "pin" << PIN_MOTOR_IN2 << "=" << in2
             << "ENA(pin" << PIN_MOTOR_ENA << ")=" << trimmedSpeed << "%";
    hardware_PWM(pi, PIN_MOTOR_ENA, MOTOR_PWM_FREQ,
                 calcDuty(trimmedSpeed));
}

void MotorController::setRight(Direction dir, int speed) {
    int in3 = 0;
    int in4 = 0;

    switch (dir) {
    case Forward:
        in3 = 0;
        in4 = 1;
        break;
    case Backward:
        in3 = 1;
        in4 = 0;
        break;
    case Stop:
        in3 = 0;
        in4 = 0;
        break;
    }
    gpio_write(pi, PIN_MOTOR_IN3, in3);
    gpio_write(pi, PIN_MOTOR_IN4, in4);

    const int trimmedSpeed = applyTrim(speed, MOTOR_RIGHT_TRIM_PERCENT);
    qDebug() << "[Motor] RIGHT: pin" << PIN_MOTOR_IN3 << "=" << in3
             << "pin" << PIN_MOTOR_IN4 << "=" << in4
             << "ENB(pin" << PIN_MOTOR_ENB << ")=" << trimmedSpeed << "%";
    hardware_PWM(pi, PIN_MOTOR_ENB, MOTOR_PWM_FREQ,
                 calcDuty(trimmedSpeed));
}

int MotorController::applyTrim(int speed, int trimPercent) {
    return qBound(0, speed, 100) * qBound(0, trimPercent, 150) / 100;
}

int MotorController::calcDuty(int percent) {

    return qBound(0, percent, 100) * 10000;
}

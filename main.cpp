#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCoreApplication>
#include <QDebug>
#include <QMetaObject>
#include <QThread>
#include <QStringList>
#include <QUrl>
#include <csignal>
#include <pigpiod_if2.h>
#include "hardware/MotorController.h"
#include "hardware/LedController.h"
#include "hardware/SpeedSensor.h"
#include "hardware/TempSensor.h"
#include "connectivity/BleServer.h"
#include "models/VehicleModel.h"

int main(int argc, char *argv[])
{
    int pi = pigpio_start(NULL, NULL);
    if (pi < 0) 
    { qDebug() << "check bug failed gpio !";
        return -1; 
    }
    qDebug() << "giao tiep duoc gpio";

    QGuiApplication app(argc, argv);

    QThread* motorThread = new QThread(&app);
    MotorController* motor = new MotorController(pi);
    motor->moveToThread(motorThread);
    motorThread->start(QThread::TimeCriticalPriority);

    LedController* lights = new LedController(pi, &app);

    QThread* speedThread = new QThread(&app);
    SpeedSensor* speed = new SpeedSensor(pi);

    speed->moveToThread(speedThread);
    QObject::connect(speedThread, &QThread::started,
                     speed, &SpeedSensor::start,
                     Qt::QueuedConnection);

    speedThread->start(QThread::HighPriority);

    QThread* bleThread = new QThread(&app);
    BleServer* ble = new BleServer();
    
    ble->moveToThread(bleThread);
    QObject::connect(bleThread, &QThread::started,
                     ble, &BleServer::start,
                     Qt::QueuedConnection);

    bleThread->start(QThread::HighPriority);

    QThread* tempThread = new QThread(&app);
    TempSensor* temp = new TempSensor(pi);
    
    temp->moveToThread(tempThread);
    QObject::connect(tempThread, &QThread::started,
                     temp, &TempSensor::start,
                     Qt::QueuedConnection);

    tempThread->start(QThread::LowPriority);


    VehicleModel vehicle;

    QObject::connect(speed, &SpeedSensor::dataUpdated,
                     &vehicle, &VehicleModel::onSensorData,
                     Qt::QueuedConnection);

    QObject::connect(temp, &TempSensor::dataUpdated,
                     &vehicle, &VehicleModel::onTemperature,
                     Qt::QueuedConnection);

    QObject::connect(ble, &BleServer::connectionChanged,
                     &vehicle, &VehicleModel::onBleConnected,
                     Qt::QueuedConnection);

    QObject::connect(ble, &BleServer::commandReceived,
        motor, [motor](const QString& cmd) {
            const QString command = cmd.trimmed().toUpper();
            const QStringList parts = command.split(':', Qt::SkipEmptyParts);
            const QString op = parts.isEmpty() ? command : parts.first();
            const int speed = parts.size() > 1 ? parts.at(1).toInt() : MOTOR_DEFAULT_SPEED;

            qDebug() << "[Motor] BLE op:" << op << "speed:" << speed;

            if      (op == "F")    motor->forward(speed);
            else if (op == "B")    motor->backward(speed);
            else if (op == "L")    motor->turnLeft(speed);
            else if (op == "R")    motor->turnRight(speed);
            else if (op == "S")    motor->stop();
        }, Qt::QueuedConnection);

    QObject::connect(ble, &BleServer::commandReceived,
        lights, [lights](const QString& cmd) {
            if      (cmd == "TL")   lights->toggleLeftSignal();
            else if (cmd == "TR")   lights->toggleRightSignal();
            else if (cmd == "HAZ")  lights->toggleHazard();
            else if (cmd == "LAMP") lights->toggleHeadLight();
        }, Qt::QueuedConnection);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("vehicle",   &vehicle);
    engine.rootContext()->setContextProperty("motorCtrl", motor);
    engine.rootContext()->setContextProperty("ledCtrl",   lights);

    const QUrl url(u"qrc:/DATN_dashboard_car/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    int ret = app.exec();

    QMetaObject::invokeMethod(motor, "stop", Qt::BlockingQueuedConnection);
    lights->allOff();
    QMetaObject::invokeMethod(speed, "stop", Qt::BlockingQueuedConnection);
    QMetaObject::invokeMethod(ble,   "stop", Qt::BlockingQueuedConnection);
    QMetaObject::invokeMethod(temp,  "stop", Qt::BlockingQueuedConnection);

    motorThread->quit(); motorThread->wait();
    speedThread->quit(); speedThread->wait();
    bleThread->quit();   bleThread->wait();
    tempThread->quit();  tempThread->wait();

    delete motor;
    delete speed;
    delete ble;
    delete temp;

    pigpio_stop(pi);
    return ret;
}

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QThread>
#include <csignal>
#include <pigpiod_if2.h>
#include "hardware/MotorController.h"
#include "hardware/SpeedSensor.h"
#include "hardware/TempSensor.h"
#include "connectivity/BleServer.h"
#include "models/VehicleModel.h"

int main(int argc, char *argv[])
{
    int pi = pigpio_start(NULL, NULL);
    if (pi < 0) { qDebug() << "pigpiod failed!"; return -1; }
    qDebug() << "pigpiod connected!";

    QGuiApplication app(argc, argv);

    //Thread 1: Motor
    QThread* motorThread = new QThread(&app);
    MotorController* motor = new MotorController(pi);
    motor->moveToThread(motorThread);
    motorThread->start(QThread::TimeCriticalPriority);

    //Thread 2: SpeedSensor
    QThread* speedThread = new QThread(&app);
    SpeedSensor* speed = new SpeedSensor(pi);
    speed->moveToThread(speedThread);
    QObject::connect(speedThread, &QThread::started,
                     speed, &SpeedSensor::start,
                     Qt::QueuedConnection);
    speedThread->start(QThread::HighPriority);

    // Thread 3: BLE
    QThread* bleThread = new QThread(&app);
    BleServer* ble = new BleServer();
    ble->moveToThread(bleThread);
    QObject::connect(bleThread, &QThread::started,
                     ble, &BleServer::start,
                     Qt::QueuedConnection);
    bleThread->start(QThread::HighPriority);

    //Thread 4: TempSensor
    QThread* tempThread = new QThread(&app);
    TempSensor* temp = new TempSensor(pi);
    temp->moveToThread(tempThread);
    QObject::connect(tempThread, &QThread::started,
                     temp, &TempSensor::start,
                     Qt::QueuedConnection);
    tempThread->start(QThread::LowPriority);

    // Main thread: VehicleModel

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

    // BLE → Motor
    QObject::connect(ble, &BleServer::commandReceived,
        motor, [motor](const QString& cmd) {
            if      (cmd.startsWith("F:"))  motor->forward(cmd.mid(2).toInt());
            else if (cmd.startsWith("B:"))  motor->backward(cmd.mid(2).toInt());
            else if (cmd.startsWith("L:"))  motor->turnLeft(cmd.mid(2).toInt());
            else if (cmd.startsWith("R:"))  motor->turnRight(cmd.mid(2).toInt());
            else if (cmd.startsWith("RL:")) motor->rotateLeft(cmd.mid(3).toInt());
            else if (cmd.startsWith("RR:")) motor->rotateRight(cmd.mid(3).toInt());
            else if (cmd == "S")            motor->stop();
        }, Qt::QueuedConnection);

    // QML
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("vehicle",   &vehicle);
    engine.rootContext()->setContextProperty("motorCtrl", motor);

    const QUrl url(u"qrc:/DATN_dashboard_car/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    int ret = app.exec();

    // Cleanup
    QMetaObject::invokeMethod(motor, "stop", Qt::BlockingQueuedConnection);
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

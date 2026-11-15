#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCoreApplication>
#include <QDebug>
#include <QMetaObject>
#include <QThread>
#include <QStringList>
#include <QUrl>
#include <QFile>
#include <QProcess>
#include <unistd.h>
#include <csignal>
#include "hardware/PigpioCompat.h"
#include "hardware/MotorController.h"
#include "hardware/LedController.h"
#include "hardware/SpeedSensor.h"
#include "hardware/TempSensor.h"
#include "connectivity/BleServer.h"
#include "models/VehicleModel.h"

int main(int argc, char *argv[])
{
#ifdef DATN_RPI_HARDWARE

    QString disp = qEnvironmentVariable("DISPLAY");
    if (disp.isEmpty() || disp.startsWith("localhost:") || disp.contains(":1")) {
        qputenv("DISPLAY", ":0");
    }

    qputenv("QT_QPA_PLATFORM", "xcb");

    if (qEnvironmentVariableIsEmpty("XAUTHORITY")) {
        if (QFile::exists("/home/pi/.Xauthority")) {
            qputenv("XAUTHORITY", "/home/pi/.Xauthority");
        } else if (QFile::exists("/home/admin/.Xauthority")) {
            qputenv("XAUTHORITY", "/home/admin/.Xauthority");
        }
    }

    pid_t myPid = getpid();
    QProcess::execute("sh", {"-c", QString("for pid in $(pgrep -x appDATN_dashboa); do if [ \"$pid\" != \"%1\" ]; then kill -9 $pid 2>/dev/null || true; fi; done").arg(myPid)});

    QProcess::execute("sh", {"-c", "sudo hciconfig hci0 reset 2>/dev/null; sudo hciconfig hci0 up 2>/dev/null || true"});
#else

    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM"))
        qputenv("QT_QPA_PLATFORM", "xcb");
#endif

    int pi = pigpio_start(NULL, NULL);
    if (pi < 0)
    { qCritical() << "pigpio_start failed with code" << pi
                  << "- check that pigpiod is running and TCP port 8888 is reachable";
        return -1;
    }
#ifdef DATN_RPI_HARDWARE
    qDebug() << "giao tiep duoc gpio";
#else
    qDebug() << "[Desktop] GPIO/I2C simulation enabled";
#endif

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

             qDebug() << "[Motor] BLE CMD" << op << "speed:" << speed;

             if (op == "F") {
                 motor->forward(speed);

             }
             else if (op == "B") {
                 motor->backward(speed);
             }
             else if (op == "L")  {
                 motor->turnLeft(speed);
             }
             else if (op == "R")  {
                 motor->turnRight(speed);
             }
             else if (op == "S")  {
                 motor->stop();
             }
         }, Qt::QueuedConnection);

     QObject::connect(ble, &BleServer::commandReceived,
         lights, [lights](const QString& cmd) {
             if      (cmd == "TL") {
                lights->toggleLeftSignal();
             }
             else if (cmd == "TR") {
                lights->toggleRightSignal();
             }
             else if (cmd == "HAZ") {
                lights->toggleHazard();
             }
             else if (cmd == "LAMP"){
                lights->toggleHeadLight();
             }
         }, Qt::QueuedConnection);

     QObject::connect(ble, &BleServer::commandReceived,
         &vehicle, [&vehicle](const QString& cmd) {
             const QString command = cmd.trimmed().toUpper();
             if (command == "THEME" || command == "NEXT_THEME") {
                 vehicle.requestTheme(-1);
             } else if (command.startsWith("THEME:")) {
                 const QStringList parts = command.split(':', Qt::SkipEmptyParts);
                 if (parts.size() > 1) {
                     vehicle.requestTheme(parts.at(1).toInt());
                 }
             }
         }, Qt::QueuedConnection);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("rpiHardware",
#ifdef DATN_RPI_HARDWARE
                                              true
#else
                                              false
#endif
    );
    engine.rootContext()->setContextProperty("vehicle",   &vehicle);
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

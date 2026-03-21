#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <pigpiod_if2.h>

#include "hardware/MotorController.h"
#include "hardware/SpeedSensor.h"
#include "connectivity/BleServer.h"

int main(int argc, char *argv[])
{
    int pi = pigpio_start(NULL, NULL);
    if (pi < 0) {
        qDebug() << "pigpiod failed!";
        return -1;
    }
    qDebug() << "pigpiod connected!";

    QGuiApplication app(argc, argv);

    // ── Hardware ──────────────────────────────────
    MotorController motor(pi);
    SpeedSensor     speed(pi);

    // ── BLE ───────────────────────────────────────
    BleServer ble;
    if (!ble.start()) {
        qDebug() << "[BLE] Failed to start!";
    }

    // BLE → Motor
    QObject::connect(&ble, &BleServer::commandReceived,
                     [&motor](const QString& cmd) {
                         qDebug() << "[CMD] Executing:" << cmd;

                         if      (cmd.startsWith("F:"))  motor.forward(cmd.mid(2).toInt());
                         else if (cmd.startsWith("B:"))  motor.backward(cmd.mid(2).toInt());
                         else if (cmd.startsWith("L:"))  motor.turnLeft(cmd.mid(2).toInt());
                         else if (cmd.startsWith("R:"))  motor.turnRight(cmd.mid(2).toInt());
                         else if (cmd.startsWith("RL:")) motor.rotateLeft(cmd.mid(3).toInt());
                         else if (cmd.startsWith("RR:")) motor.rotateRight(cmd.mid(3).toInt());
                         else if (cmd == "S")            motor.stop();
                     });

    
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("speedSensor", &speed);
    engine.rootContext()->setContextProperty("bleServer",   &ble);
    engine.rootContext()->setContextProperty("motorCtrl",   &motor);

    const QUrl url(u"qrc:/DATN_dashboard_car/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    speed.start();

    int ret = app.exec();

    motor.stop();
    speed.stop();
    pigpio_stop(pi);
    return ret;
}

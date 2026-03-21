#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDebug>
#include <pigpiod_if2.h>
#include "SpeedSensor.h"

int main(int argc, char *argv[])
{
    int pi = pigpio_start(NULL, NULL);
    if (pi < 0) {
        qDebug() << "Cannot connect to pigpiod!";
        return -1;
    }

    QGuiApplication app(argc, argv);

    SpeedSensor speedSensor(pi);
    speedSensor.start();

    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/DATN_dashboard_car/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    int ret = app.exec();
    pigpio_stop(pi);
    return ret;
}

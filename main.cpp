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
#include <QTimer>
#include <QRegularExpression>
#include <memory>
#include <unistd.h>
#include <csignal>
#include "hardware/PigpioCompat.h"
#include "hardware/MotorController.h"
#include "hardware/LedController.h"
#include "hardware/SpeedSensor.h"
#include "hardware/TempSensor.h"
#include "hardware/ConsoleInputWorker.h"
#include "connectivity/BleServer.h"
#include "models/VehicleModel.h"

int main(int argc, char *argv[])
{
    // Check command line arguments:
    // By default, GUI is OFF (runs in CLI / command-line mode).
    // Pass --gui or -g to enable the QML graphical dashboard.
    bool enableGui = false;
    for (int i = 1; i < argc; ++i) {
        QString arg = QString::fromUtf8(argv[i]);
        if (arg == "--gui" || arg == "-g") {
            enableGui = true;
        } else if (arg == "--no-gui" || arg == "--cli" || arg == "-c") {
            enableGui = false;
        }
    }

#ifdef DATN_RPI_HARDWARE
    if (enableGui) {
        // ALWAYS force X11 / xcb on Raspberry Pi when displaying on the physical DSI screen.
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
    }

    // Single-instance enforcement: kill any other running instances of this app (from autostart or prior build)
    pid_t myPid = getpid();
    QProcess::execute("sh", {"-c", QString("pgrep -f appDATN_dashboa | grep -v %1 | xargs -r kill -9 2>/dev/null || true").arg(myPid)});

    // Restart and reset Bluetooth BLE adapter to start fresh with the new app instance
    QProcess::execute("sh", {"-c", "sudo hciconfig hci0 reset 2>/dev/null; sudo hciconfig hci0 up 2>/dev/null || true"});
#else
    if (enableGui) {
        if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM"))
            qputenv("QT_QPA_PLATFORM", "xcb");
    }
#endif

    int pi = pigpio_start(NULL, NULL);
    if (pi < 0)
    {
        qCritical() << "pigpio_start failed with code" << pi
                    << "- check that pigpiod is running and TCP port 8888 is reachable";
        return -1; 
    }
#ifdef DATN_RPI_HARDWARE
    qDebug() << "giao tiep duoc gpio";
#else
    qDebug() << "[Desktop] GPIO/I2C simulation enabled";
#endif

    std::unique_ptr<QCoreApplication> app;
    if (enableGui) {
        app = std::make_unique<QGuiApplication>(argc, argv);
    } else {
        app = std::make_unique<QCoreApplication>(argc, argv);
    }

    QThread* motorThread = new QThread(app.get());
    MotorController* motor = new MotorController(pi);
    motor->moveToThread(motorThread);
    motorThread->start(QThread::TimeCriticalPriority);

    LedController* lights = new LedController(pi, app.get());

    QThread* speedThread = new QThread(app.get());
    SpeedSensor* speed = new SpeedSensor(pi);
    speed->moveToThread(speedThread);
    QObject::connect(speedThread, &QThread::started,
                     speed, &SpeedSensor::start,
                     Qt::QueuedConnection);
    speedThread->start(QThread::HighPriority);

    QThread* bleThread = new QThread(app.get());
    BleServer* ble = new BleServer();
    ble->moveToThread(bleThread);
    QObject::connect(bleThread, &QThread::started,
                     ble, &BleServer::start,
                     Qt::QueuedConnection);
    bleThread->start(QThread::HighPriority);

    QThread* tempThread = new QThread(app.get());
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
            const int speedVal = parts.size() > 1 ? parts.at(1).toInt() : MOTOR_DEFAULT_SPEED;

            qInfo() << "[BLE CMD]" << op << "speed:" << speedVal;

            if (op == "F") {
                motor->forward(speedVal);
            }
            else if (op == "B") {
                motor->backward(speedVal);
            }
            else if (op == "L")  {
                motor->turnLeft(speedVal);
            }
            else if (op == "R")  {
                motor->turnRight(speedVal);
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

    QThread* consoleThread = nullptr;
    ConsoleInputWorker* consoleWorker = nullptr;
    std::unique_ptr<QQmlApplicationEngine> engine;

    if (!enableGui) {
        qInfo().noquote() << "\n================================================================";
        qInfo().noquote() << "       DATN CAR CONTROLLER - COMMAND LINE (CLI) MODE            ";
        qInfo().noquote() << "================================================================";
        qInfo().noquote() << " [✓] GUI is OFF. Running pure command-line backend.";
        qInfo().noquote() << " [✓] BLE, Motor, SpeedSensor, TempSensor & LEDs are ACTIVE.";
        qInfo().noquote() << " [✓] Advertising as 'DATN-Car' on Bluetooth.";
        qInfo().noquote() << "----------------------------------------------------------------";
        qInfo().noquote() << " Type commands in terminal (or control via Android app):";
        qInfo().noquote() << "   f [spd]  : Tien (Forward)      b [spd]  : Lui (Backward)";
        qInfo().noquote() << "   l [spd]  : Trai (Turn Left)    r [spd]  : Phai (Turn Right)";
        qInfo().noquote() << "   s        : Dung (Stop)         status   : Xem trang thai";
        qInfo().noquote() << "   tl / tr  : Xi nhan Trai/Phai   haz      : Den khan cap";
        qInfo().noquote() << "   lamp     : Den pha             q        : Thoat";
        qInfo().noquote() << "================================================================\n";

        consoleThread = new QThread(app.get());
        consoleWorker = new ConsoleInputWorker();
        consoleWorker->moveToThread(consoleThread);

        QObject::connect(consoleThread, &QThread::started, consoleWorker, &ConsoleInputWorker::run);
        QObject::connect(consoleWorker, &ConsoleInputWorker::commandEntered, app.get(),
            [&vehicle, motor, lights, appPtr = app.get()](const QString& line) {
            const QString input = line.trimmed();
            const QStringList tokens = input.split(QRegularExpression("\\s+|:"), Qt::SkipEmptyParts);
            if (tokens.isEmpty()) return;
            const QString cmd = tokens.first().toUpper();
            const int speedVal = tokens.size() > 1 ? tokens.at(1).toInt() : MOTOR_DEFAULT_SPEED;

            if (cmd == "F" || cmd == "TIEN") {
                QMetaObject::invokeMethod(motor, "forward", Qt::QueuedConnection, Q_ARG(int, speedVal));
                qInfo().noquote() << "[CLI CMD] FORWARD | Speed:" << speedVal;
            } else if (cmd == "B" || cmd == "LUI") {
                QMetaObject::invokeMethod(motor, "backward", Qt::QueuedConnection, Q_ARG(int, speedVal));
                qInfo().noquote() << "[CLI CMD] BACKWARD | Speed:" << speedVal;
            } else if (cmd == "L" || cmd == "TRAI") {
                QMetaObject::invokeMethod(motor, "turnLeft", Qt::QueuedConnection, Q_ARG(int, speedVal));
                qInfo().noquote() << "[CLI CMD] TURN LEFT | Speed:" << speedVal;
            } else if (cmd == "R" || cmd == "PHAI") {
                QMetaObject::invokeMethod(motor, "turnRight", Qt::QueuedConnection, Q_ARG(int, speedVal));
                qInfo().noquote() << "[CLI CMD] TURN RIGHT | Speed:" << speedVal;
            } else if (cmd == "S" || cmd == "STOP" || cmd == "DUNG") {
                QMetaObject::invokeMethod(motor, "stop", Qt::QueuedConnection);
                qInfo().noquote() << "[CLI CMD] STOP";
            } else if (cmd == "TL") {
                lights->toggleLeftSignal();
                qInfo().noquote() << "[CLI CMD] Left Signal:" << (lights->leftSignal() ? "ON" : "OFF");
            } else if (cmd == "TR") {
                lights->toggleRightSignal();
                qInfo().noquote() << "[CLI CMD] Right Signal:" << (lights->rightSignal() ? "ON" : "OFF");
            } else if (cmd == "HAZ") {
                lights->toggleHazard();
                qInfo().noquote() << "[CLI CMD] Hazard:" << (lights->hazardActive() ? "ON" : "OFF");
            } else if (cmd == "LAMP") {
                lights->toggleHeadLight();
                qInfo().noquote() << "[CLI CMD] Headlight:" << (lights->headLight() ? "ON" : "OFF");
            } else if (cmd == "STATUS" || cmd == "ST") {
                qInfo().noquote() << QString("[Status] Speed: %1 km/h (%2 RPM) | Temp: %3 °C | BLE: %4 | Headlight: %5 | Hazard: %6")
                    .arg(vehicle.speed() * 3.6f, 0, 'f', 1)
                    .arg(vehicle.rpm(), 0, 'f', 0)
                    .arg(vehicle.temperature(), 0, 'f', 1)
                    .arg(vehicle.bleConnected() ? "Connected" : "Disconnected")
                    .arg(lights->headLight() ? "ON" : "OFF")
                    .arg(lights->hazardActive() ? "ON" : "OFF");
            } else if (cmd == "HELP" || cmd == "H" || cmd == "?") {
                qInfo().noquote() << "\nAvailable Commands:";
                qInfo().noquote() << "  f [spd]  : Forward (0-255, default 180)";
                qInfo().noquote() << "  b [spd]  : Backward";
                qInfo().noquote() << "  l [spd]  : Turn Left";
                qInfo().noquote() << "  r [spd]  : Turn Right";
                qInfo().noquote() << "  s        : Stop";
                qInfo().noquote() << "  tl / tr  : Turn Left / Right Signal";
                qInfo().noquote() << "  haz      : Hazard warning";
                qInfo().noquote() << "  lamp     : Headlight";
                qInfo().noquote() << "  status   : Vehicle telemetry";
                qInfo().noquote() << "  q        : Exit\n";
            } else if (cmd == "Q" || cmd == "QUIT" || cmd == "EXIT") {
                qInfo().noquote() << "[CLI] Exiting...";
                appPtr->quit();
            } else {
                qInfo().noquote() << "[CLI] Unknown command:" << input << "(Type 'help' for commands)";
            }
        });

        consoleThread->start();

        // Periodic telemetry log (every 3 seconds)
        QTimer* telemetryTimer = new QTimer(app.get());
        QObject::connect(telemetryTimer, &QTimer::timeout, [&]() {
            qInfo().noquote() << QString("[Telemetry] Speed: %1 km/h (%2 RPM) | Temp: %3 °C | BLE: %4")
                .arg(vehicle.speed() * 3.6f, 0, 'f', 1)
                .arg(vehicle.rpm(), 0, 'f', 0)
                .arg(vehicle.temperature(), 0, 'f', 1)
                .arg(vehicle.bleConnected() ? "Connected" : "Disconnected");
        });
        telemetryTimer->start(3000);
    } else {
        engine = std::make_unique<QQmlApplicationEngine>();
        engine->rootContext()->setContextProperty("rpiHardware",
#ifdef DATN_RPI_HARDWARE
                                                  true
#else
                                                  false
#endif
        );
        engine->rootContext()->setContextProperty("vehicle",   &vehicle);
        engine->rootContext()->setContextProperty("ledCtrl",   lights);

        const QUrl url(u"qrc:/DATN_dashboard_car/Main.qml"_qs);
        QObject::connect(engine.get(), &QQmlApplicationEngine::objectCreationFailed,
            app.get(), []() { QCoreApplication::exit(-1); },
            Qt::QueuedConnection);
        engine->load(url);
    }

    int ret = app->exec();

    if (consoleThread) {
        consoleThread->requestInterruption();
        consoleThread->quit();
        consoleThread->wait(300);
        delete consoleWorker;
    }

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

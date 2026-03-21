#pragma once
#include <QObject>
#include <QProcess>
#include <QDebug>

class BleServer : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY connectionChanged)

public:
    explicit BleServer(QObject* parent = nullptr) : QObject(parent) {}
    ~BleServer() { stop(); }

    bool start() {
        m_process = new QProcess(this);
        m_process->setProgram("python3");
        m_process->setArguments({"/home/quangha/ble_server.py"});

        connect(m_process, &QProcess::readyReadStandardOutput,
                this, &BleServer::onStdout);
        connect(m_process, &QProcess::readyReadStandardError, this, [this]() {
            qDebug() << "[BLE-py err]" << m_process->readAllStandardError();
        });
        connect(m_process, &QProcess::started, []() {
            qDebug() << "[BLE] Python BLE server started!";
        });

        m_process->start();
        return m_process->waitForStarted(3000);
    }

    void stop() {
        if (m_process) {
            m_process->terminate();
            m_process->waitForFinished(2000);
        }
    }

    bool connected() const { return m_connected; }

signals:
    void commandReceived(const QString& cmd);
    void connectionChanged(bool connected);

private slots:
    void onStdout() {
        while (m_process->canReadLine()) {
            QString line = QString::fromUtf8(
                               m_process->readLine()).trimmed();

            if (line.startsWith("CMD:")) {
                QString cmd = line.mid(4).toUpper();
                qDebug() << "[BLE] Command:" << cmd;
                if (!m_connected) {
                    m_connected = true;
                    emit connectionChanged(true);
                }
                emit commandReceived(cmd);

            } else if (line.startsWith("LOG:")) {
                qDebug() << "[BLE-py]" << line.mid(4);
            }
        }
    }

private:
    QProcess* m_process   = nullptr;
    bool      m_connected = false;
};

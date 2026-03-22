#include "BleServer.h"

BleServer::BleServer(QObject* parent) : QObject(parent) {}

BleServer::~BleServer() {
    stop();
}

bool BleServer::start() {
    m_process = new QProcess(this);
    m_process->setProgram("python3");
    m_process->setArguments({"/home/quangha/ble_server.py"});
    m_process->setStandardInputFile(QProcess::nullDevice());

    connect(m_process, &QProcess::readyReadStandardOutput,
            this, &BleServer::onStdout);
    connect(m_process, &QProcess::readyReadStandardError, this, [this]() {
        qDebug() << "[BLE-py err]" << m_process->readAllStandardError();
    });

    m_process->start();
    return m_process->waitForStarted(3000);
}

void BleServer::stop() {
    if (m_process && m_process->state() != QProcess::NotRunning) {
        m_process->terminate();
        if (!m_process->waitForFinished(2000)) {
            m_process->kill();
        }
    }
}

void BleServer::onStdout() {
    if (!m_process) return;
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

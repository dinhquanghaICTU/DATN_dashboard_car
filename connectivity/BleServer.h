#pragma once
#include <QObject>
#include <QProcess>
#include <QDebug>

class BleServer : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY connectionChanged)

public:
    explicit BleServer(QObject* parent = nullptr);
    ~BleServer() override;

    bool connected() const { return m_connected; }

public slots:
    Q_INVOKABLE bool start();
    Q_INVOKABLE void stop();

signals:
    void commandReceived(const QString& cmd);
    void connectionChanged(bool connected);

private slots:
    void onStdout();

private:
    QProcess* m_process   = nullptr;
    bool      m_connected = false;
};

#pragma once

#include <QMap>
#include <QObject>
#include <QStringList>
#include <QVariantMap>
#include <QtDBus/QDBusMessage>
#include <QtDBus/QDBusObjectPath>

class BleGattApplication;

using BleInterfaceMap = QMap<QString, QVariantMap>;
using BleManagedObjectMap = QMap<QDBusObjectPath, BleInterfaceMap>;

Q_DECLARE_METATYPE(BleInterfaceMap)
Q_DECLARE_METATYPE(BleManagedObjectMap)

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
    void onInterfacesAdded(const QDBusObjectPath& path,
                           const BleInterfaceMap& interfaces);
    void onInterfacesRemoved(const QDBusObjectPath& path,
                             const QStringList& interfaces);
    void onPropertiesChanged(const QString& interface,
                             const QVariantMap& changedProperties,
                             const QStringList& invalidatedProperties,
                             const QDBusMessage& message);

private:
    friend class BleGattApplication;

    bool configureAdapter();
    bool setAdapterProperty(const QString& property, const QVariant& value);
    void connectBlueZSignals();
    void disconnectBlueZSignals();
    void loadExistingDevices();
    void processDevice(const QDBusObjectPath& path,
                       const QVariantMap& properties);
    void fetchAndProcessDevice(const QDBusObjectPath& path);
    void rejectDevice(const QDBusObjectPath& path,
                      const QString& address);
    void handleCommand(const QString& command);
    void setConnected(bool connected);

    BleGattApplication* m_application = nullptr;
    QDBusObjectPath m_currentDevicePath;
    QString m_currentDeviceAddress;
    bool m_connected = false;
    bool m_running = false;
};

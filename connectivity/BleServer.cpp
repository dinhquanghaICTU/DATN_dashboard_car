#include "BleServer.h"

#include <QDebug>
#include <QMap>
#include <QVariantMap>
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusMessage>
#include <QtDBus/QDBusObjectPath>
#include <QtDBus/QDBusPendingCallWatcher>
#include <QtDBus/QDBusPendingReply>
#include <QtDBus/QDBusReply>
#include <QtDBus/QDBusVariant>
#include <QtDBus/QDBusVirtualObject>
#include <QtDBus/QDBusMetaType>

namespace {
constexpr auto BLUEZ_SERVICE = "org.bluez";
constexpr auto ADAPTER_PATH = "/org/bluez/hci0";
constexpr auto GATT_MANAGER_IFACE = "org.bluez.GattManager1";
constexpr auto GATT_SERVICE_IFACE = "org.bluez.GattService1";
constexpr auto GATT_CHRC_IFACE = "org.bluez.GattCharacteristic1";
constexpr auto LE_ADV_MANAGER_IFACE = "org.bluez.LEAdvertisingManager1";
constexpr auto LE_ADV_IFACE = "org.bluez.LEAdvertisement1";
constexpr auto ADAPTER_IFACE = "org.bluez.Adapter1";
constexpr auto DEVICE_IFACE = "org.bluez.Device1";
constexpr auto DBUS_OM_IFACE = "org.freedesktop.DBus.ObjectManager";
constexpr auto DBUS_PROP_IFACE = "org.freedesktop.DBus.Properties";
constexpr auto DBUS_INTROSPECT_IFACE = "org.freedesktop.DBus.Introspectable";

constexpr auto APP_PATH = "/org/bluez/datn";
constexpr auto SERVICE_PATH = "/org/bluez/datn/service0";
constexpr auto CHARACTERISTIC_PATH = "/org/bluez/datn/service0/char0";
constexpr auto ADVERTISEMENT_PATH = "/org/bluez/datn/adv";

constexpr auto SERVICE_UUID = "12345678-1234-1234-1234-123456789abc";
constexpr auto CHARACTERISTIC_UUID = "12345678-1234-1234-1234-123456789abd";

}

class BleGattApplication final : public QDBusVirtualObject {
public:
    explicit BleGattApplication(BleServer* owner)
        : QDBusVirtualObject(owner), m_owner(owner)
    {
        qDBusRegisterMetaType<BleInterfaceMap>();
        qDBusRegisterMetaType<BleManagedObjectMap>();
    }

    QString introspect(const QString& path) const override
    {
        if (path == QLatin1String(APP_PATH)) {
            return QStringLiteral(
                "<node>"
                "<interface name=\"org.freedesktop.DBus.ObjectManager\">"
                "<method name=\"GetManagedObjects\">"
                "<arg name=\"objects\" type=\"a{oa{sa{sv}}}\" direction=\"out\"/>"
                "</method>"
                "</interface>"
                "<node name=\"service0\"/>"
                "<node name=\"adv\"/>"
                "</node>");
        }

        if (path == QLatin1String(SERVICE_PATH)) {
            return QStringLiteral(
                "<node>"
                "<interface name=\"org.freedesktop.DBus.Properties\">"
                "<method name=\"GetAll\">"
                "<arg name=\"interface\" type=\"s\" direction=\"in\"/>"
                "<arg name=\"properties\" type=\"a{sv}\" direction=\"out\"/>"
                "</method>"
                "</interface>"
                "<interface name=\"org.bluez.GattService1\"/>"
                "<node name=\"char0\"/>"
                "</node>");
        }

        if (path == QLatin1String(CHARACTERISTIC_PATH)) {
            return QStringLiteral(
                "<node>"
                "<interface name=\"org.freedesktop.DBus.Properties\">"
                "<method name=\"GetAll\">"
                "<arg name=\"interface\" type=\"s\" direction=\"in\"/>"
                "<arg name=\"properties\" type=\"a{sv}\" direction=\"out\"/>"
                "</method>"
                "</interface>"
                "<interface name=\"org.bluez.GattCharacteristic1\">"
                "<method name=\"WriteValue\">"
                "<arg name=\"value\" type=\"ay\" direction=\"in\"/>"
                "<arg name=\"options\" type=\"a{sv}\" direction=\"in\"/>"
                "</method>"
                "</interface>"
                "</node>");
        }

        if (path == QLatin1String(ADVERTISEMENT_PATH)) {
            return QStringLiteral(
                "<node>"
                "<interface name=\"org.freedesktop.DBus.Properties\">"
                "<method name=\"GetAll\">"
                "<arg name=\"interface\" type=\"s\" direction=\"in\"/>"
                "<arg name=\"properties\" type=\"a{sv}\" direction=\"out\"/>"
                "</method>"
                "</interface>"
                "<interface name=\"org.bluez.LEAdvertisement1\">"
                "<method name=\"Release\"/>"
                "</interface>"
                "</node>");
        }

        return QStringLiteral("<node/>");
    }

    bool handleMessage(const QDBusMessage& message,
                       const QDBusConnection& connection) override
    {
        const QString path = message.path();
        const QString interface = message.interface();
        const QString member = message.member();

        if (interface == QLatin1String(DBUS_INTROSPECT_IFACE)
            && member == QLatin1String("Introspect")) {
            return connection.send(
                message.createReply(QVariant::fromValue(introspect(path))));
        }

        if (path == QLatin1String(APP_PATH)
            && interface == QLatin1String(DBUS_OM_IFACE)
            && member == QLatin1String("GetManagedObjects")) {
            return connection.send(
                message.createReply({QVariant::fromValue(managedObjects())}));
        }

        if (interface == QLatin1String(DBUS_PROP_IFACE)
            && member == QLatin1String("GetAll")) {
            const QString requestedInterface =
                message.arguments().value(0).toString();
            return connection.send(
                message.createReply(
                    QVariant::fromValue(
                        properties(path, requestedInterface))));
        }

        if (path == QLatin1String(CHARACTERISTIC_PATH)
            && interface == QLatin1String(GATT_CHRC_IFACE)
            && member == QLatin1String("WriteValue")) {
            const QByteArray value = message.arguments().value(0).toByteArray();
            m_owner->handleCommand(QString::fromUtf8(value));
            return connection.send(message.createReply());
        }

        if (path == QLatin1String(ADVERTISEMENT_PATH)
            && interface == QLatin1String(LE_ADV_IFACE)
            && member == QLatin1String("Release")) {
            qDebug() << "[BLE] Advertisement released by BlueZ";
            return connection.send(message.createReply());
        }

        return false;
    }

    void registerWithBlueZ()
    {
        QDBusInterface gattManager(
            QLatin1String(BLUEZ_SERVICE),
            QLatin1String(ADAPTER_PATH),
            QLatin1String(GATT_MANAGER_IFACE),
            QDBusConnection::systemBus());

        auto* watcher = new QDBusPendingCallWatcher(
            gattManager.asyncCall(
                QStringLiteral("RegisterApplication"),
                QVariant::fromValue(QDBusObjectPath(QLatin1String(APP_PATH))),
                QVariantMap{}),
            this);

        QObject::connect(
            watcher, &QDBusPendingCallWatcher::finished,
            this, [this](QDBusPendingCallWatcher* call) {
                const QDBusPendingReply<> reply = *call;
                call->deleteLater();

                if (reply.isError()) {
                    qCritical() << "[BLE] GATT registration failed:"
                                << reply.error().name()
                                << reply.error().message();
                    return;
                }

                qDebug() << "[BLE] GATT application registered";
                registerAdvertisement();
            });
    }

    void unregisterFromBlueZ()
    {
        QDBusInterface advertisementManager(
            QLatin1String(BLUEZ_SERVICE),
            QLatin1String(ADAPTER_PATH),
            QLatin1String(LE_ADV_MANAGER_IFACE),
            QDBusConnection::systemBus());
        advertisementManager.call(
            QStringLiteral("UnregisterAdvertisement"),
            QVariant::fromValue(
                QDBusObjectPath(QLatin1String(ADVERTISEMENT_PATH))));

        QDBusInterface gattManager(
            QLatin1String(BLUEZ_SERVICE),
            QLatin1String(ADAPTER_PATH),
            QLatin1String(GATT_MANAGER_IFACE),
            QDBusConnection::systemBus());
        gattManager.call(
            QStringLiteral("UnregisterApplication"),
            QVariant::fromValue(QDBusObjectPath(QLatin1String(APP_PATH))));
    }

private:
    QVariantMap serviceProperties() const
    {
        return {
            {QStringLiteral("UUID"), QString::fromLatin1(SERVICE_UUID)},
            {QStringLiteral("Primary"), true},
        };
    }

    QVariantMap characteristicProperties() const
    {
        return {
            {QStringLiteral("UUID"), QString::fromLatin1(CHARACTERISTIC_UUID)},
            {QStringLiteral("Service"),
             QVariant::fromValue(
                 QDBusObjectPath(QLatin1String(SERVICE_PATH)))},
            {QStringLiteral("Flags"),
             QStringList{QStringLiteral("write"),
                         QStringLiteral("write-without-response")}},
        };
    }

    QVariantMap advertisementProperties() const
    {
        return {
            {QStringLiteral("Type"), QStringLiteral("peripheral")},
            {QStringLiteral("ServiceUUIDs"),
             QStringList{QString::fromLatin1(SERVICE_UUID)}},
            {QStringLiteral("LocalName"), QStringLiteral("DATN-Car")},
        };
    }

    QVariantMap properties(const QString& path,
                           const QString& requestedInterface) const
    {
        if (path == QLatin1String(SERVICE_PATH)
            && requestedInterface == QLatin1String(GATT_SERVICE_IFACE)) {
            return serviceProperties();
        }

        if (path == QLatin1String(CHARACTERISTIC_PATH)
            && requestedInterface == QLatin1String(GATT_CHRC_IFACE)) {
            return characteristicProperties();
        }

        if (path == QLatin1String(ADVERTISEMENT_PATH)
            && requestedInterface == QLatin1String(LE_ADV_IFACE)) {
            return advertisementProperties();
        }

        return {};
    }

    BleManagedObjectMap managedObjects() const
    {
        return {
            {QDBusObjectPath(QLatin1String(SERVICE_PATH)),
             {{QString::fromLatin1(GATT_SERVICE_IFACE),
               serviceProperties()}}},
            {QDBusObjectPath(QLatin1String(CHARACTERISTIC_PATH)),
             {{QString::fromLatin1(GATT_CHRC_IFACE),
               characteristicProperties()}}},
        };
    }

    void registerAdvertisement()
    {
        QDBusInterface advertisementManager(
            QLatin1String(BLUEZ_SERVICE),
            QLatin1String(ADAPTER_PATH),
            QLatin1String(LE_ADV_MANAGER_IFACE),
            QDBusConnection::systemBus());

        auto* watcher = new QDBusPendingCallWatcher(
            advertisementManager.asyncCall(
                QStringLiteral("RegisterAdvertisement"),
                QVariant::fromValue(
                    QDBusObjectPath(QLatin1String(ADVERTISEMENT_PATH))),
                QVariantMap{}),
            this);

        QObject::connect(
            watcher, &QDBusPendingCallWatcher::finished,
            this, [](QDBusPendingCallWatcher* call) {
                const QDBusPendingReply<> reply = *call;
                call->deleteLater();

                if (reply.isError()) {
                    qCritical() << "[BLE] Advertisement registration failed:"
                                << reply.error().name()
                                << reply.error().message();
                    return;
                }

                qDebug() << "[BLE] Advertising as DATN-Car";
            });
    }

    BleServer* m_owner;
};

BleServer::BleServer(QObject* parent)
    : QObject(parent)
{
}

BleServer::~BleServer()
{
    stop();
}

bool BleServer::start()
{
    if (m_running)
        return true;

    QDBusConnection bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qCritical() << "[BLE] Cannot connect to system D-Bus:"
                    << bus.lastError().message();
        return false;
    }

    qDBusRegisterMetaType<BleInterfaceMap>();
    qDBusRegisterMetaType<BleManagedObjectMap>();

    if (!configureAdapter())
        return false;

    connectBlueZSignals();
    loadExistingDevices();

    m_application = new BleGattApplication(this);
    if (!bus.registerVirtualObject(
            QLatin1String(APP_PATH),
            m_application,
            QDBusConnection::SubPath)) {
        qCritical() << "[BLE] Cannot export GATT objects:"
                    << bus.lastError().message();
        delete m_application;
        m_application = nullptr;
        disconnectBlueZSignals();
        return false;
    }

    m_running = true;
    m_application->registerWithBlueZ();
    return true;
}

void BleServer::stop()
{
    if (!m_running)
        return;

    m_application->unregisterFromBlueZ();
    disconnectBlueZSignals();
    QDBusConnection::systemBus().unregisterObject(
        QLatin1String(APP_PATH),
        QDBusConnection::UnregisterTree);

    delete m_application;
    m_application = nullptr;
    m_running = false;
    m_currentDevicePath = QDBusObjectPath();
    m_currentDeviceAddress.clear();
    setConnected(false);
}

bool BleServer::configureAdapter()
{
    return setAdapterProperty(QStringLiteral("Powered"), true)
        && setAdapterProperty(QStringLiteral("Alias"),
                              QStringLiteral("DATN-Car"))
        && setAdapterProperty(QStringLiteral("Discoverable"), true)
        && setAdapterProperty(QStringLiteral("Pairable"), true);
}

bool BleServer::setAdapterProperty(const QString& property,
                                   const QVariant& value)
{
    QDBusInterface properties(
        QLatin1String(BLUEZ_SERVICE),
        QLatin1String(ADAPTER_PATH),
        QLatin1String(DBUS_PROP_IFACE),
        QDBusConnection::systemBus());

    const QDBusMessage reply = properties.call(
        QStringLiteral("Set"),
        QString::fromLatin1(ADAPTER_IFACE),
        property,
        QVariant::fromValue(QDBusVariant(value)));

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qCritical() << "[BLE] Cannot set adapter property" << property
                    << ":" << reply.errorName()
                    << reply.errorMessage();
        return false;
    }

    return true;
}

void BleServer::connectBlueZSignals()
{
    QDBusConnection bus = QDBusConnection::systemBus();

    bus.connect(
        QLatin1String(BLUEZ_SERVICE),
        QStringLiteral("/"),
        QLatin1String(DBUS_OM_IFACE),
        QStringLiteral("InterfacesAdded"),
        this,
        SLOT(onInterfacesAdded(QDBusObjectPath,BleInterfaceMap)));

    bus.connect(
        QLatin1String(BLUEZ_SERVICE),
        QStringLiteral("/"),
        QLatin1String(DBUS_OM_IFACE),
        QStringLiteral("InterfacesRemoved"),
        this,
        SLOT(onInterfacesRemoved(QDBusObjectPath,QStringList)));

    bus.connect(
        QLatin1String(BLUEZ_SERVICE),
        QString(),
        QLatin1String(DBUS_PROP_IFACE),
        QStringLiteral("PropertiesChanged"),
        this,
        SLOT(onPropertiesChanged(QString,QVariantMap,QStringList,QDBusMessage)));
}

void BleServer::disconnectBlueZSignals()
{
    QDBusConnection bus = QDBusConnection::systemBus();

    bus.disconnect(
        QLatin1String(BLUEZ_SERVICE),
        QStringLiteral("/"),
        QLatin1String(DBUS_OM_IFACE),
        QStringLiteral("InterfacesAdded"),
        this,
        SLOT(onInterfacesAdded(QDBusObjectPath,BleInterfaceMap)));

    bus.disconnect(
        QLatin1String(BLUEZ_SERVICE),
        QStringLiteral("/"),
        QLatin1String(DBUS_OM_IFACE),
        QStringLiteral("InterfacesRemoved"),
        this,
        SLOT(onInterfacesRemoved(QDBusObjectPath,QStringList)));

    bus.disconnect(
        QLatin1String(BLUEZ_SERVICE),
        QString(),
        QLatin1String(DBUS_PROP_IFACE),
        QStringLiteral("PropertiesChanged"),
        this,
        SLOT(onPropertiesChanged(QString,QVariantMap,QStringList,QDBusMessage)));
}

void BleServer::loadExistingDevices()
{
    QDBusInterface objectManager(
        QLatin1String(BLUEZ_SERVICE),
        QStringLiteral("/"),
        QLatin1String(DBUS_OM_IFACE),
        QDBusConnection::systemBus());

    const QDBusReply<BleManagedObjectMap> reply =
        objectManager.call(QStringLiteral("GetManagedObjects"));

    if (!reply.isValid()) {
        qWarning() << "[BLE] Cannot list existing devices:"
                   << reply.error().message();
        return;
    }

    const BleManagedObjectMap objects = reply.value();
    for (auto it = objects.cbegin(); it != objects.cend(); ++it) {
        const auto device = it.value().constFind(
            QString::fromLatin1(DEVICE_IFACE));
        if (device != it.value().cend())
            processDevice(it.key(), device.value());
    }
}

void BleServer::onInterfacesAdded(const QDBusObjectPath& path,
                                  const BleInterfaceMap& interfaces)
{
    const auto device = interfaces.constFind(
        QString::fromLatin1(DEVICE_IFACE));
    if (device != interfaces.cend())
        processDevice(path, device.value());
}

void BleServer::onInterfacesRemoved(const QDBusObjectPath& path,
                                    const QStringList& interfaces)
{
    if (!interfaces.contains(QString::fromLatin1(DEVICE_IFACE)))
        return;

    if (path.path() != m_currentDevicePath.path())
        return;

    qDebug() << "[BLE] Device removed:" << m_currentDeviceAddress;
    m_currentDevicePath = QDBusObjectPath();
    m_currentDeviceAddress.clear();
    setConnected(false);
}

void BleServer::onPropertiesChanged(
    const QString& interface,
    const QVariantMap& changedProperties,
    const QStringList& invalidatedProperties,
    const QDBusMessage& message)
{
    Q_UNUSED(invalidatedProperties)

    if (interface != QLatin1String(DEVICE_IFACE))
        return;

    const QDBusObjectPath path(message.path());
    if (changedProperties.contains(QStringLiteral("Connected"))) {
        QVariantMap properties = changedProperties;

        if (!properties.contains(QStringLiteral("Address"))
            || !properties.contains(QStringLiteral("Name"))) {
            fetchAndProcessDevice(path);
            return;
        }

        processDevice(path, properties);
    }
}

void BleServer::fetchAndProcessDevice(const QDBusObjectPath& path)
{
    QDBusInterface properties(
        QLatin1String(BLUEZ_SERVICE),
        path.path(),
        QLatin1String(DBUS_PROP_IFACE),
        QDBusConnection::systemBus());

    const QDBusReply<QVariantMap> reply = properties.call(
        QStringLiteral("GetAll"),
        QString::fromLatin1(DEVICE_IFACE));

    if (!reply.isValid()) {
        qWarning() << "[BLE] Cannot read device properties for"
                   << path.path() << ":" << reply.error().message();
        return;
    }

    processDevice(path, reply.value());
}

void BleServer::processDevice(const QDBusObjectPath& path,
                              const QVariantMap& properties)
{
    const bool connected =
        properties.value(QStringLiteral("Connected")).toBool();
    const QString address =
        properties.value(QStringLiteral("Address")).toString();
    const QString name =
        properties.value(QStringLiteral("Name"),
                         properties.value(QStringLiteral("Alias")))
            .toString();

    qDebug() << "[BLE] Device" << address << "(" << name
             << ") connected =" << connected;

    if (!connected) {
        if (path.path() == m_currentDevicePath.path()) {
            qDebug() << "[BLE] Slot freed:" << m_currentDeviceAddress;
            m_currentDevicePath = QDBusObjectPath();
            m_currentDeviceAddress.clear();
            setConnected(false);
        }
        return;
    }

    if (m_currentDevicePath.path().isEmpty()
        || path.path() == m_currentDevicePath.path()) {
        m_currentDevicePath = path;
        m_currentDeviceAddress = address;
        qDebug() << "[BLE] Accepted device:" << address;
        setConnected(true);
        return;
    }

    rejectDevice(path, address);
}

void BleServer::rejectDevice(const QDBusObjectPath& path,
                             const QString& address)
{
    qWarning() << "[BLE] Rejecting device" << address
               << "- already connected:" << m_currentDeviceAddress;

    QDBusInterface device(
        QLatin1String(BLUEZ_SERVICE),
        path.path(),
        QLatin1String(DEVICE_IFACE),
        QDBusConnection::systemBus());
    device.asyncCall(QStringLiteral("Disconnect"));

    QDBusInterface properties(
        QLatin1String(BLUEZ_SERVICE),
        path.path(),
        QLatin1String(DBUS_PROP_IFACE),
        QDBusConnection::systemBus());
    properties.asyncCall(
        QStringLiteral("Set"),
        QString::fromLatin1(DEVICE_IFACE),
        QStringLiteral("Trusted"),
        QVariant::fromValue(QDBusVariant(false)));
}

void BleServer::handleCommand(const QString& command)
{
    const QString normalized = command.trimmed().toUpper();
    if (normalized.isEmpty())
        return;

    qDebug() << "[BLE] Command:" << normalized;
    setConnected(true);
    emit commandReceived(normalized);
}

void BleServer::setConnected(bool connected)
{
    if (m_connected == connected)
        return;

    m_connected = connected;
    emit connectionChanged(m_connected);
}

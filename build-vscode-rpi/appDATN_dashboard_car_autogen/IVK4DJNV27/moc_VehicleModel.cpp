/****************************************************************************
** Meta object code from reading C++ file 'VehicleModel.h'
**
** Created by: The Qt Meta Object Compiler version 68 (Qt 6.5.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../models/VehicleModel.h"
#include <QtCore/qmetatype.h>

#if __has_include(<QtCore/qtmochelpers.h>)
#include <QtCore/qtmochelpers.h>
#else
QT_BEGIN_MOC_NAMESPACE
#endif


#include <memory>

#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'VehicleModel.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 68
#error "This file was generated using the moc from 6.5.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {

#ifdef QT_MOC_HAS_STRINGDATA
struct qt_meta_stringdata_CLASSVehicleModelENDCLASS_t {};
static constexpr auto qt_meta_stringdata_CLASSVehicleModelENDCLASS = QtMocHelpers::stringData(
    "VehicleModel",
    "dataChanged",
    "",
    "tempChanged",
    "bleChanged",
    "onSensorData",
    "rpm",
    "speed",
    "onTemperature",
    "temp",
    "onBleConnected",
    "connected",
    "temperature",
    "bleConnected"
);
#else  // !QT_MOC_HAS_STRING_DATA
struct qt_meta_stringdata_CLASSVehicleModelENDCLASS_t {
    uint offsetsAndSizes[28];
    char stringdata0[13];
    char stringdata1[12];
    char stringdata2[1];
    char stringdata3[12];
    char stringdata4[11];
    char stringdata5[13];
    char stringdata6[4];
    char stringdata7[6];
    char stringdata8[14];
    char stringdata9[5];
    char stringdata10[15];
    char stringdata11[10];
    char stringdata12[12];
    char stringdata13[13];
};
#define QT_MOC_LITERAL(ofs, len) \
    uint(sizeof(qt_meta_stringdata_CLASSVehicleModelENDCLASS_t::offsetsAndSizes) + ofs), len 
Q_CONSTINIT static const qt_meta_stringdata_CLASSVehicleModelENDCLASS_t qt_meta_stringdata_CLASSVehicleModelENDCLASS = {
    {
        QT_MOC_LITERAL(0, 12),  // "VehicleModel"
        QT_MOC_LITERAL(13, 11),  // "dataChanged"
        QT_MOC_LITERAL(25, 0),  // ""
        QT_MOC_LITERAL(26, 11),  // "tempChanged"
        QT_MOC_LITERAL(38, 10),  // "bleChanged"
        QT_MOC_LITERAL(49, 12),  // "onSensorData"
        QT_MOC_LITERAL(62, 3),  // "rpm"
        QT_MOC_LITERAL(66, 5),  // "speed"
        QT_MOC_LITERAL(72, 13),  // "onTemperature"
        QT_MOC_LITERAL(86, 4),  // "temp"
        QT_MOC_LITERAL(91, 14),  // "onBleConnected"
        QT_MOC_LITERAL(106, 9),  // "connected"
        QT_MOC_LITERAL(116, 11),  // "temperature"
        QT_MOC_LITERAL(128, 12)   // "bleConnected"
    },
    "VehicleModel",
    "dataChanged",
    "",
    "tempChanged",
    "bleChanged",
    "onSensorData",
    "rpm",
    "speed",
    "onTemperature",
    "temp",
    "onBleConnected",
    "connected",
    "temperature",
    "bleConnected"
};
#undef QT_MOC_LITERAL
#endif // !QT_MOC_HAS_STRING_DATA
} // unnamed namespace

Q_CONSTINIT static const uint qt_meta_data_CLASSVehicleModelENDCLASS[] = {

 // content:
      11,       // revision
       0,       // classname
       0,    0, // classinfo
       6,   14, // methods
       4,   64, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       3,       // signalCount

 // signals: name, argc, parameters, tag, flags, initial metatype offsets
       1,    0,   50,    2, 0x06,    5 /* Public */,
       3,    0,   51,    2, 0x06,    6 /* Public */,
       4,    0,   52,    2, 0x06,    7 /* Public */,

 // slots: name, argc, parameters, tag, flags, initial metatype offsets
       5,    2,   53,    2, 0x0a,    8 /* Public */,
       8,    1,   58,    2, 0x0a,   11 /* Public */,
      10,    1,   61,    2, 0x0a,   13 /* Public */,

 // signals: parameters
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,

 // slots: parameters
    QMetaType::Void, QMetaType::Float, QMetaType::Float,    6,    7,
    QMetaType::Void, QMetaType::Float,    9,
    QMetaType::Void, QMetaType::Bool,   11,

 // properties: name, type, flags
       6, QMetaType::Float, 0x00015001, uint(0), 0,
       7, QMetaType::Float, 0x00015001, uint(0), 0,
      12, QMetaType::Float, 0x00015001, uint(1), 0,
      13, QMetaType::Bool, 0x00015001, uint(2), 0,

       0        // eod
};

Q_CONSTINIT const QMetaObject VehicleModel::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_meta_stringdata_CLASSVehicleModelENDCLASS.offsetsAndSizes,
    qt_meta_data_CLASSVehicleModelENDCLASS,
    qt_static_metacall,
    nullptr,
    qt_incomplete_metaTypeArray<qt_meta_stringdata_CLASSVehicleModelENDCLASS_t,
        // property 'rpm'
        QtPrivate::TypeAndForceComplete<float, std::true_type>,
        // property 'speed'
        QtPrivate::TypeAndForceComplete<float, std::true_type>,
        // property 'temperature'
        QtPrivate::TypeAndForceComplete<float, std::true_type>,
        // property 'bleConnected'
        QtPrivate::TypeAndForceComplete<bool, std::true_type>,
        // Q_OBJECT / Q_GADGET
        QtPrivate::TypeAndForceComplete<VehicleModel, std::true_type>,
        // method 'dataChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'tempChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'bleChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'onSensorData'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<float, std::false_type>,
        QtPrivate::TypeAndForceComplete<float, std::false_type>,
        // method 'onTemperature'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<float, std::false_type>,
        // method 'onBleConnected'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<bool, std::false_type>
    >,
    nullptr
} };

void VehicleModel::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<VehicleModel *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->dataChanged(); break;
        case 1: _t->tempChanged(); break;
        case 2: _t->bleChanged(); break;
        case 3: _t->onSensorData((*reinterpret_cast< std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<float>>(_a[2]))); break;
        case 4: _t->onTemperature((*reinterpret_cast< std::add_pointer_t<float>>(_a[1]))); break;
        case 5: _t->onBleConnected((*reinterpret_cast< std::add_pointer_t<bool>>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (VehicleModel::*)();
            if (_t _q_method = &VehicleModel::dataChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (VehicleModel::*)();
            if (_t _q_method = &VehicleModel::tempChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 1;
                return;
            }
        }
        {
            using _t = void (VehicleModel::*)();
            if (_t _q_method = &VehicleModel::bleChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 2;
                return;
            }
        }
    }else if (_c == QMetaObject::ReadProperty) {
        auto *_t = static_cast<VehicleModel *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< float*>(_v) = _t->rpm(); break;
        case 1: *reinterpret_cast< float*>(_v) = _t->speed(); break;
        case 2: *reinterpret_cast< float*>(_v) = _t->temperature(); break;
        case 3: *reinterpret_cast< bool*>(_v) = _t->bleConnected(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
    } else if (_c == QMetaObject::ResetProperty) {
    } else if (_c == QMetaObject::BindableProperty) {
    }
}

const QMetaObject *VehicleModel::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *VehicleModel::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_CLASSVehicleModelENDCLASS.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int VehicleModel::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 6)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 6;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 6)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 6;
    }else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    }
    return _id;
}

// SIGNAL 0
void VehicleModel::dataChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void VehicleModel::tempChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void VehicleModel::bleChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}
QT_WARNING_POP

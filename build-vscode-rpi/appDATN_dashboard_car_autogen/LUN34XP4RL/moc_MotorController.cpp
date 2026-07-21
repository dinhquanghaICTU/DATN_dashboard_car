/****************************************************************************
** Meta object code from reading C++ file 'MotorController.h'
**
** Created by: The Qt Meta Object Compiler version 68 (Qt 6.5.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../hardware/MotorController.h"
#include <QtCore/qmetatype.h>

#if __has_include(<QtCore/qtmochelpers.h>)
#include <QtCore/qtmochelpers.h>
#else
QT_BEGIN_MOC_NAMESPACE
#endif


#include <memory>

#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'MotorController.h' doesn't include <QObject>."
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
struct qt_meta_stringdata_CLASSMotorControllerENDCLASS_t {};
static constexpr auto qt_meta_stringdata_CLASSMotorControllerENDCLASS = QtMocHelpers::stringData(
    "MotorController",
    "speedChanged",
    "",
    "speed",
    "forward",
    "backward",
    "turnLeft",
    "turnRight",
    "rotateLeft",
    "rotateRight",
    "stop",
    "setSpeed"
);
#else  // !QT_MOC_HAS_STRING_DATA
struct qt_meta_stringdata_CLASSMotorControllerENDCLASS_t {
    uint offsetsAndSizes[24];
    char stringdata0[16];
    char stringdata1[13];
    char stringdata2[1];
    char stringdata3[6];
    char stringdata4[8];
    char stringdata5[9];
    char stringdata6[9];
    char stringdata7[10];
    char stringdata8[11];
    char stringdata9[12];
    char stringdata10[5];
    char stringdata11[9];
};
#define QT_MOC_LITERAL(ofs, len) \
    uint(sizeof(qt_meta_stringdata_CLASSMotorControllerENDCLASS_t::offsetsAndSizes) + ofs), len 
Q_CONSTINIT static const qt_meta_stringdata_CLASSMotorControllerENDCLASS_t qt_meta_stringdata_CLASSMotorControllerENDCLASS = {
    {
        QT_MOC_LITERAL(0, 15),  // "MotorController"
        QT_MOC_LITERAL(16, 12),  // "speedChanged"
        QT_MOC_LITERAL(29, 0),  // ""
        QT_MOC_LITERAL(30, 5),  // "speed"
        QT_MOC_LITERAL(36, 7),  // "forward"
        QT_MOC_LITERAL(44, 8),  // "backward"
        QT_MOC_LITERAL(53, 8),  // "turnLeft"
        QT_MOC_LITERAL(62, 9),  // "turnRight"
        QT_MOC_LITERAL(72, 10),  // "rotateLeft"
        QT_MOC_LITERAL(83, 11),  // "rotateRight"
        QT_MOC_LITERAL(95, 4),  // "stop"
        QT_MOC_LITERAL(100, 8)   // "setSpeed"
    },
    "MotorController",
    "speedChanged",
    "",
    "speed",
    "forward",
    "backward",
    "turnLeft",
    "turnRight",
    "rotateLeft",
    "rotateRight",
    "stop",
    "setSpeed"
};
#undef QT_MOC_LITERAL
#endif // !QT_MOC_HAS_STRING_DATA
} // unnamed namespace

Q_CONSTINIT static const uint qt_meta_data_CLASSMotorControllerENDCLASS[] = {

 // content:
      11,       // revision
       0,       // classname
       0,    0, // classinfo
      15,   14, // methods
       1,  135, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       1,       // signalCount

 // signals: name, argc, parameters, tag, flags, initial metatype offsets
       1,    1,  104,    2, 0x06,    2 /* Public */,

 // slots: name, argc, parameters, tag, flags, initial metatype offsets
       4,    1,  107,    2, 0x0a,    4 /* Public */,
       4,    0,  110,    2, 0x2a,    6 /* Public | MethodCloned */,
       5,    1,  111,    2, 0x0a,    7 /* Public */,
       5,    0,  114,    2, 0x2a,    9 /* Public | MethodCloned */,
       6,    1,  115,    2, 0x0a,   10 /* Public */,
       6,    0,  118,    2, 0x2a,   12 /* Public | MethodCloned */,
       7,    1,  119,    2, 0x0a,   13 /* Public */,
       7,    0,  122,    2, 0x2a,   15 /* Public | MethodCloned */,
       8,    1,  123,    2, 0x0a,   16 /* Public */,
       8,    0,  126,    2, 0x2a,   18 /* Public | MethodCloned */,
       9,    1,  127,    2, 0x0a,   19 /* Public */,
       9,    0,  130,    2, 0x2a,   21 /* Public | MethodCloned */,
      10,    0,  131,    2, 0x0a,   22 /* Public */,
      11,    1,  132,    2, 0x0a,   23 /* Public */,

 // signals: parameters
    QMetaType::Void, QMetaType::Int,    3,

 // slots: parameters
    QMetaType::Void, QMetaType::Int,    3,
    QMetaType::Void,
    QMetaType::Void, QMetaType::Int,    3,
    QMetaType::Void,
    QMetaType::Void, QMetaType::Int,    3,
    QMetaType::Void,
    QMetaType::Void, QMetaType::Int,    3,
    QMetaType::Void,
    QMetaType::Void, QMetaType::Int,    3,
    QMetaType::Void,
    QMetaType::Void, QMetaType::Int,    3,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void, QMetaType::Int,    3,

 // properties: name, type, flags
       3, QMetaType::Int, 0x00015103, uint(0), 0,

       0        // eod
};

Q_CONSTINIT const QMetaObject MotorController::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_meta_stringdata_CLASSMotorControllerENDCLASS.offsetsAndSizes,
    qt_meta_data_CLASSMotorControllerENDCLASS,
    qt_static_metacall,
    nullptr,
    qt_incomplete_metaTypeArray<qt_meta_stringdata_CLASSMotorControllerENDCLASS_t,
        // property 'speed'
        QtPrivate::TypeAndForceComplete<int, std::true_type>,
        // Q_OBJECT / Q_GADGET
        QtPrivate::TypeAndForceComplete<MotorController, std::true_type>,
        // method 'speedChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        // method 'forward'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        // method 'forward'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'backward'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        // method 'backward'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'turnLeft'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        // method 'turnLeft'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'turnRight'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        // method 'turnRight'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'rotateLeft'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        // method 'rotateLeft'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'rotateRight'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        // method 'rotateRight'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'stop'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'setSpeed'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>
    >,
    nullptr
} };

void MotorController::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<MotorController *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->speedChanged((*reinterpret_cast< std::add_pointer_t<int>>(_a[1]))); break;
        case 1: _t->forward((*reinterpret_cast< std::add_pointer_t<int>>(_a[1]))); break;
        case 2: _t->forward(); break;
        case 3: _t->backward((*reinterpret_cast< std::add_pointer_t<int>>(_a[1]))); break;
        case 4: _t->backward(); break;
        case 5: _t->turnLeft((*reinterpret_cast< std::add_pointer_t<int>>(_a[1]))); break;
        case 6: _t->turnLeft(); break;
        case 7: _t->turnRight((*reinterpret_cast< std::add_pointer_t<int>>(_a[1]))); break;
        case 8: _t->turnRight(); break;
        case 9: _t->rotateLeft((*reinterpret_cast< std::add_pointer_t<int>>(_a[1]))); break;
        case 10: _t->rotateLeft(); break;
        case 11: _t->rotateRight((*reinterpret_cast< std::add_pointer_t<int>>(_a[1]))); break;
        case 12: _t->rotateRight(); break;
        case 13: _t->stop(); break;
        case 14: _t->setSpeed((*reinterpret_cast< std::add_pointer_t<int>>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (MotorController::*)(int );
            if (_t _q_method = &MotorController::speedChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 0;
                return;
            }
        }
    }else if (_c == QMetaObject::ReadProperty) {
        auto *_t = static_cast<MotorController *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< int*>(_v) = _t->speed(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
        auto *_t = static_cast<MotorController *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setSpeed(*reinterpret_cast< int*>(_v)); break;
        default: break;
        }
    } else if (_c == QMetaObject::ResetProperty) {
    } else if (_c == QMetaObject::BindableProperty) {
    }
}

const QMetaObject *MotorController::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *MotorController::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_CLASSMotorControllerENDCLASS.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int MotorController::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 15)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 15;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 15)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 15;
    }else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 1;
    }
    return _id;
}

// SIGNAL 0
void MotorController::speedChanged(int _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}
QT_WARNING_POP

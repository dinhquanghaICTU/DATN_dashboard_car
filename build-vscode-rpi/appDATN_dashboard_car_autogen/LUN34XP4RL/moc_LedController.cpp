/****************************************************************************
** Meta object code from reading C++ file 'LedController.h'
**
** Created by: The Qt Meta Object Compiler version 68 (Qt 6.5.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../hardware/LedController.h"
#include <QtCore/qmetatype.h>

#if __has_include(<QtCore/qtmochelpers.h>)
#include <QtCore/qtmochelpers.h>
#else
QT_BEGIN_MOC_NAMESPACE
#endif


#include <memory>

#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'LedController.h' doesn't include <QObject>."
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
struct qt_meta_stringdata_CLASSLedControllerENDCLASS_t {};
static constexpr auto qt_meta_stringdata_CLASSLedControllerENDCLASS = QtMocHelpers::stringData(
    "LedController",
    "stateChanged",
    "",
    "setLeftSignal",
    "enabled",
    "setRightSignal",
    "setHazard",
    "setHeadLight",
    "toggleLeftSignal",
    "toggleRightSignal",
    "toggleHazard",
    "toggleHeadLight",
    "allOff",
    "onBlink",
    "leftSignal",
    "rightSignal",
    "headLight"
);
#else  // !QT_MOC_HAS_STRING_DATA
struct qt_meta_stringdata_CLASSLedControllerENDCLASS_t {
    uint offsetsAndSizes[34];
    char stringdata0[14];
    char stringdata1[13];
    char stringdata2[1];
    char stringdata3[14];
    char stringdata4[8];
    char stringdata5[15];
    char stringdata6[10];
    char stringdata7[13];
    char stringdata8[17];
    char stringdata9[18];
    char stringdata10[13];
    char stringdata11[16];
    char stringdata12[7];
    char stringdata13[8];
    char stringdata14[11];
    char stringdata15[12];
    char stringdata16[10];
};
#define QT_MOC_LITERAL(ofs, len) \
    uint(sizeof(qt_meta_stringdata_CLASSLedControllerENDCLASS_t::offsetsAndSizes) + ofs), len 
Q_CONSTINIT static const qt_meta_stringdata_CLASSLedControllerENDCLASS_t qt_meta_stringdata_CLASSLedControllerENDCLASS = {
    {
        QT_MOC_LITERAL(0, 13),  // "LedController"
        QT_MOC_LITERAL(14, 12),  // "stateChanged"
        QT_MOC_LITERAL(27, 0),  // ""
        QT_MOC_LITERAL(28, 13),  // "setLeftSignal"
        QT_MOC_LITERAL(42, 7),  // "enabled"
        QT_MOC_LITERAL(50, 14),  // "setRightSignal"
        QT_MOC_LITERAL(65, 9),  // "setHazard"
        QT_MOC_LITERAL(75, 12),  // "setHeadLight"
        QT_MOC_LITERAL(88, 16),  // "toggleLeftSignal"
        QT_MOC_LITERAL(105, 17),  // "toggleRightSignal"
        QT_MOC_LITERAL(123, 12),  // "toggleHazard"
        QT_MOC_LITERAL(136, 15),  // "toggleHeadLight"
        QT_MOC_LITERAL(152, 6),  // "allOff"
        QT_MOC_LITERAL(159, 7),  // "onBlink"
        QT_MOC_LITERAL(167, 10),  // "leftSignal"
        QT_MOC_LITERAL(178, 11),  // "rightSignal"
        QT_MOC_LITERAL(190, 9)   // "headLight"
    },
    "LedController",
    "stateChanged",
    "",
    "setLeftSignal",
    "enabled",
    "setRightSignal",
    "setHazard",
    "setHeadLight",
    "toggleLeftSignal",
    "toggleRightSignal",
    "toggleHazard",
    "toggleHeadLight",
    "allOff",
    "onBlink",
    "leftSignal",
    "rightSignal",
    "headLight"
};
#undef QT_MOC_LITERAL
#endif // !QT_MOC_HAS_STRING_DATA
} // unnamed namespace

Q_CONSTINIT static const uint qt_meta_data_CLASSLedControllerENDCLASS[] = {

 // content:
      11,       // revision
       0,       // classname
       0,    0, // classinfo
      11,   14, // methods
       3,   99, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       1,       // signalCount

 // signals: name, argc, parameters, tag, flags, initial metatype offsets
       1,    0,   80,    2, 0x06,    4 /* Public */,

 // slots: name, argc, parameters, tag, flags, initial metatype offsets
       3,    1,   81,    2, 0x0a,    5 /* Public */,
       5,    1,   84,    2, 0x0a,    7 /* Public */,
       6,    1,   87,    2, 0x0a,    9 /* Public */,
       7,    1,   90,    2, 0x0a,   11 /* Public */,
       8,    0,   93,    2, 0x0a,   13 /* Public */,
       9,    0,   94,    2, 0x0a,   14 /* Public */,
      10,    0,   95,    2, 0x0a,   15 /* Public */,
      11,    0,   96,    2, 0x0a,   16 /* Public */,
      12,    0,   97,    2, 0x0a,   17 /* Public */,
      13,    0,   98,    2, 0x08,   18 /* Private */,

 // signals: parameters
    QMetaType::Void,

 // slots: parameters
    QMetaType::Void, QMetaType::Bool,    4,
    QMetaType::Void, QMetaType::Bool,    4,
    QMetaType::Void, QMetaType::Bool,    4,
    QMetaType::Void, QMetaType::Bool,    4,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,

 // properties: name, type, flags
      14, QMetaType::Bool, 0x00015001, uint(0), 0,
      15, QMetaType::Bool, 0x00015001, uint(0), 0,
      16, QMetaType::Bool, 0x00015001, uint(0), 0,

       0        // eod
};

Q_CONSTINIT const QMetaObject LedController::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_meta_stringdata_CLASSLedControllerENDCLASS.offsetsAndSizes,
    qt_meta_data_CLASSLedControllerENDCLASS,
    qt_static_metacall,
    nullptr,
    qt_incomplete_metaTypeArray<qt_meta_stringdata_CLASSLedControllerENDCLASS_t,
        // property 'leftSignal'
        QtPrivate::TypeAndForceComplete<bool, std::true_type>,
        // property 'rightSignal'
        QtPrivate::TypeAndForceComplete<bool, std::true_type>,
        // property 'headLight'
        QtPrivate::TypeAndForceComplete<bool, std::true_type>,
        // Q_OBJECT / Q_GADGET
        QtPrivate::TypeAndForceComplete<LedController, std::true_type>,
        // method 'stateChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'setLeftSignal'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<bool, std::false_type>,
        // method 'setRightSignal'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<bool, std::false_type>,
        // method 'setHazard'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<bool, std::false_type>,
        // method 'setHeadLight'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<bool, std::false_type>,
        // method 'toggleLeftSignal'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'toggleRightSignal'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'toggleHazard'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'toggleHeadLight'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'allOff'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'onBlink'
        QtPrivate::TypeAndForceComplete<void, std::false_type>
    >,
    nullptr
} };

void LedController::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<LedController *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->stateChanged(); break;
        case 1: _t->setLeftSignal((*reinterpret_cast< std::add_pointer_t<bool>>(_a[1]))); break;
        case 2: _t->setRightSignal((*reinterpret_cast< std::add_pointer_t<bool>>(_a[1]))); break;
        case 3: _t->setHazard((*reinterpret_cast< std::add_pointer_t<bool>>(_a[1]))); break;
        case 4: _t->setHeadLight((*reinterpret_cast< std::add_pointer_t<bool>>(_a[1]))); break;
        case 5: _t->toggleLeftSignal(); break;
        case 6: _t->toggleRightSignal(); break;
        case 7: _t->toggleHazard(); break;
        case 8: _t->toggleHeadLight(); break;
        case 9: _t->allOff(); break;
        case 10: _t->onBlink(); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (LedController::*)();
            if (_t _q_method = &LedController::stateChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 0;
                return;
            }
        }
    }else if (_c == QMetaObject::ReadProperty) {
        auto *_t = static_cast<LedController *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< bool*>(_v) = _t->leftSignal(); break;
        case 1: *reinterpret_cast< bool*>(_v) = _t->rightSignal(); break;
        case 2: *reinterpret_cast< bool*>(_v) = _t->headLight(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
    } else if (_c == QMetaObject::ResetProperty) {
    } else if (_c == QMetaObject::BindableProperty) {
    }
}

const QMetaObject *LedController::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *LedController::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_CLASSLedControllerENDCLASS.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int LedController::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 11)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 11;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 11)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 11;
    }else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 3;
    }
    return _id;
}

// SIGNAL 0
void LedController::stateChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}
QT_WARNING_POP

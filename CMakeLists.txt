cmake_minimum_required(VERSION 3.16)

project(DATN_dashboard_car VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick Core Network DBus Multimedia)

qt_standard_project_setup()
qt_policy(SET QTP0001 NEW)

qt_add_executable(appDATN_dashboard_car
    main.cpp
    hardware/MotorController.cpp    hardware/MotorController.h
    hardware/LedController.cpp      hardware/LedController.h
    hardware/SpeedSensor.cpp        hardware/SpeedSensor.h
    hardware/TempSensor.cpp         hardware/TempSensor.h
    connectivity/BleServer.cpp      connectivity/BleServer.h
    models/VehicleModel.h
    config/AppConfig.h
)

qt_add_qml_module(appDATN_dashboard_car
    URI DATN_dashboard_car
    VERSION 1.0
    RESOURCE_PREFIX /
    NO_CACHEGEN
    QML_FILES Main.qml
    ui/components/SpeedGauge.qml
    ui/components/TempDisplay.qml
    ui/components/MotorControl.qml
    ui/components/VoiceIndicator.qml
    ui/components/TopBar.qml
    ui/components/LeftDashboardPanel.qml
    ui/components/CenterGaugePanel.qml
    ui/components/RightStatsPanel.qml
    ui/components/IntroOverlay.qml
    RESOURCES assets/intro.mp4
)

set_target_properties(appDATN_dashboard_car PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_include_directories(appDATN_dashboard_car PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/config
    ${CMAKE_CURRENT_SOURCE_DIR}/hardware
    ${CMAKE_CURRENT_SOURCE_DIR}/connectivity
    ${CMAKE_CURRENT_SOURCE_DIR}/models
)

find_library(PIGPIOD_IF2_LIB
    NAMES pigpiod_if2
    PATHS
        ${CMAKE_SYSROOT}/usr/lib
        ${CMAKE_SYSROOT}/usr/local/lib
    REQUIRED
)

message(STATUS "Found pigpiod_if2: ${PIGPIOD_IF2_LIB}")

target_link_libraries(appDATN_dashboard_car
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Core
    PRIVATE Qt6::Network
    PRIVATE Qt6::DBus
    PRIVATE Qt6::Multimedia
    PRIVATE ${PIGPIOD_IF2_LIB}
    PRIVATE pthread rt
)

install(TARGETS appDATN_dashboard_car
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

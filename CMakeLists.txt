cmake_minimum_required(VERSION 3.16)

project(DATN_dashboard_car VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick)

qt_standard_project_setup()

qt_add_executable(appDATN_dashboard_car
    main.cpp
    # Hardware
        hardware/MotorController.cpp
        hardware/LedController.cpp
        hardware/SpeedSensor.cpp
        hardware/TempSensor.cpp
        # Middleware
        middleware/AppController.cpp
        middleware/CommandExecutor.cpp
        # Connectivity
        connectivity/BleServer.cpp
        connectivity/ApiManager.cpp
        # Voice
        voice/VoiceController.cpp
        voice/WakeWordDetector.cpp
        voice/AudioRecorder.cpp
        # Models
        models/VehicleModel.cpp
        models/VoiceModel.cpp
)

qt_add_qml_module(appDATN_dashboard_car
    URI DATN_dashboard_car
    VERSION 1.0
    QML_FILES Main.qml
    ui/components/SpeedGauge.qml
    ui/components/TempDisplay.qml
    ui/components/MotorControl.qml
    ui/components/VoiceIndicator.qml
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
    ${CMAKE_CURRENT_SOURCE_DIR}/middleware
    ${CMAKE_CURRENT_SOURCE_DIR}/connectivity
    ${CMAKE_CURRENT_SOURCE_DIR}/voice
    ${CMAKE_CURRENT_SOURCE_DIR}/models
)

target_link_libraries(appDATN_dashboard_car
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Core
    PRIVATE Qt6::Network
#    PRIVATE Qt6::Multimedia
#    PRIVATE Qt6::Bluetooth]]
    PRIVATE ${PIGPIOD_IF2_LIB}
    PRIVATE pthread rt
)

install(TARGETS appDATN_dashboard_car
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

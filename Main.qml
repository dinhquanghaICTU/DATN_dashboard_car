import QtQuick 2.15
import QtQuick.Window 2.15
import "ui/components"

Window {
    id: root
    visible: true
    x: 0
    y: 38
    width: 800
    height: 480
    color: bgColor
    title: "DATN Dashboard"

    // Desktop Qt and RPi Qt were built without QtMultimedia QML backend.
    // Dashboard appears immediately.
    property bool introActive: false
    property int themeIndex: 0
    property string themeName: themeIndex === 0 ? "AQUA" : themeIndex === 1 ? "FOREST" : "AMBER"
    property color bgColor: themeIndex === 0 ? "#080c12" : themeIndex === 1 ? "#07100c" : "#100d08"
    property color cardBg: themeIndex === 0 ? "#0a101d" : themeIndex === 1 ? "#081510" : "#15110a"
    property color cardBorder: themeIndex === 0 ? Qt.rgba(0, 0.9, 0.8, 0.22) : themeIndex === 1 ? Qt.rgba(0.35, 0.84, 0.55, 0.22) : Qt.rgba(1.0, 0.7, 0.28, 0.22)
    property color primaryLine: themeIndex === 0 ? Qt.rgba(0, 0.9, 0.8, 0.12) : themeIndex === 1 ? Qt.rgba(0.35, 0.84, 0.55, 0.12) : Qt.rgba(1.0, 0.7, 0.28, 0.12)
    property color primaryBorder: themeIndex === 0 ? Qt.rgba(0, 0.9, 0.8, 0.15) : themeIndex === 1 ? Qt.rgba(0.35, 0.84, 0.55, 0.15) : Qt.rgba(1.0, 0.7, 0.28, 0.15)
    property color rpmBorder: themeIndex === 0 ? Qt.rgba(0.6, 0.4, 1, 0.2) : themeIndex === 1 ? Qt.rgba(0.49, 0.78, 1, 0.2) : Qt.rgba(1, 0.56, 0.44, 0.2)
    property color tempBorder: themeIndex === 0 ? Qt.rgba(1, 0.67, 0, 0.2) : themeIndex === 1 ? Qt.rgba(1, 0.82, 0.4, 0.2) : Qt.rgba(1, 0.62, 0.11, 0.2)
    property color accentBorder: themeIndex === 0 ? Qt.rgba(0, 1, 0.5, 0.2) : themeIndex === 1 ? Qt.rgba(0.72, 0.95, 0.78, 0.2) : Qt.rgba(1, 0.88, 0.48, 0.2)
    property color warningBorder: themeIndex === 0 ? Qt.rgba(1, 0.8, 0, 0.2) : themeIndex === 1 ? Qt.rgba(0.96, 0.82, 0.37, 0.2) : Qt.rgba(1, 0.8, 0.4, 0.2)
    property color primary: themeIndex === 0 ? "#00e5cc" : themeIndex === 1 ? "#58d68d" : "#ffb347"
    property color accent: themeIndex === 0 ? "#00ff88" : themeIndex === 1 ? "#00ffaa" : "#ffe17a"
    property color speedColor: themeIndex === 0 ? "#00d4ff" : themeIndex === 1 ? "#7ee8a7" : "#ffc857"
    property color rpmColor: themeIndex === 0 ? "#9966ff" : themeIndex === 1 ? "#7cc7ff" : "#ff8f70"
    property color tempColor: themeIndex === 0 ? "#ffaa00" : themeIndex === 1 ? "#ffd166" : "#ff9f1c"
    property color warningColor: themeIndex === 0 ? "#ffcc00" : themeIndex === 1 ? "#f4d35e" : "#ffcc66"
    property color dangerColor: "#ff4444"
    property color displayTempColor: vehicle.temperature > 50.0 ? dangerColor : tempColor
    property color topPanelColor: themeIndex === 0 ? Qt.rgba(0, 0.55, 0.48, 0.35) : themeIndex === 1 ? Qt.rgba(0.18, 0.62, 0.32, 0.35) : Qt.rgba(0.85, 0.34, 0.05, 0.35)
    property color weatherPanelColor: themeIndex === 0 ? "#101827" : themeIndex === 1 ? "#10160f" : "#1f1208"
    property color rainColor: themeIndex === 0 ? "#ff4fd8" : themeIndex === 1 ? "#b36bff" : "#ff8533"
    property color weatherIconColor: weatherMode === "sun" ? (themeIndex === 2 ? dangerColor : "#ffd21f") : weatherMode === "rain" ? rainColor : "#d8eef6"
    property string weatherMode: "rain"

    property bool leftSignal: ledCtrl.leftSignal
    property bool rightSignal: ledCtrl.rightSignal
    property bool headLight: ledCtrl.headLight
    property int signalTick: 0
    property real batteryLevel: 100.0
    property bool batteryBlinkOn: true
    property bool batteryCriticalVisible: batteryLevel >= 10.0 || batteryBlinkOn
    property real displaySpeed: vehicle.speed
    property real displaySpeedKmh: displaySpeed * 3.6
    property real displayRpm: vehicle.rpm
    property bool tempHazardActive: false
    property bool temperatureHazardLocked: vehicle.temperature > 50.0

    onBatteryLevelChanged: if (batteryLevel >= 10.0) batteryBlinkOn = true

    function updateTemperatureHazard() {
        if (temperatureHazardLocked && !tempHazardActive) {
            tempHazardActive = true
            ledCtrl.setHazard(true)
        } else if (!temperatureHazardLocked && tempHazardActive) {
            tempHazardActive = false
            ledCtrl.setHazard(false)
        }
    }

    function applyTheme(index) {
        root.themeIndex = index
    }

    function nextTheme() {
        root.themeIndex = (root.themeIndex + 1) % 3
    }

    function finishIntro() {
        if (!introActive) return
        introActive = false
    }

    Connections {
        target: vehicle
        function onTempChanged() {
            updateTemperatureHazard()
        }
    }

    Timer {
        interval: 500
        running: leftSignal || rightSignal
        repeat: true
        onTriggered: signalTick = (signalTick + 1) % 2
    }

    Timer {
        interval: 400
        running: batteryLevel < 10.0
        repeat: true
        onTriggered: batteryBlinkOn = !batteryBlinkOn
        onRunningChanged: if (!running) batteryBlinkOn = true
    }

    Item {
        id: dashboard
        anchors.fill: parent
        visible: !introActive
        opacity: introActive ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: primary
            border.width: 3
            radius: 28
            z: 100
        }

        TopBar {
            x: 0; y: 4
            width: 800; height: 44
            introActive: root.introActive
            bgColor: root.bgColor
            primary: root.primary
            topPanelColor: root.topPanelColor
            weatherPanelColor: root.weatherPanelColor
            weatherMode: root.weatherMode
            weatherIconColor: root.weatherIconColor
        }

        LeftDashboardPanel {
            x: 14; y: 50
            width: 220; height: 416
            themeIndex: root.themeIndex
            themeName: root.themeName
            primary: root.primary
            accent: root.accent
            cardBg: root.cardBg
            cardBorder: root.cardBorder
            warningColor: root.warningColor
            dangerColor: root.dangerColor
            tempColor: root.tempColor
            displayTempColor: root.displayTempColor
            batteryLevel: root.batteryLevel
            batteryCriticalVisible: root.batteryCriticalVisible
            temperature: vehicle.temperature
            onApplyTheme: (index) => root.applyTheme(index)
            onNextTheme: root.nextTheme()
        }

        CenterGaugePanel {
            x: 248; y: 50
            width: 300; height: 416
            introActive: root.introActive
            themeIndex: root.themeIndex
            primary: root.primary
            accent: root.accent
            cardBg: root.cardBg
            cardBorder: root.cardBorder
            warningColor: root.warningColor
            dangerColor: root.dangerColor
            bgColor: root.bgColor
            rpmColor: root.rpmColor
            displaySpeed: root.displaySpeed
            displaySpeedKmh: root.displaySpeedKmh
            displayRpm: root.displayRpm
            leftSignal: root.leftSignal
            rightSignal: root.rightSignal
            hazardActive: ledCtrl.hazardActive
            headLight: root.headLight
            signalTick: root.signalTick
            onToggleLeftSignal: ledCtrl.toggleLeftSignal()
            onToggleRightSignal: ledCtrl.toggleRightSignal()
            onToggleHazard: ledCtrl.toggleHazard()
            onToggleHeadLight: ledCtrl.toggleHeadLight()
        }

        RightStatsPanel {
            x: 562; y: 50
            width: 224; height: 416
            themeIndex: root.themeIndex
            primary: root.primary
            accent: root.accent
            cardBg: root.cardBg
            cardBorder: root.cardBorder
            dangerColor: root.dangerColor
            warningColor: root.warningColor
            displaySpeedKmh: root.displaySpeedKmh
            tripDistanceKm: 1.5
        }
    }

    Loader {
        id: introLoader
        anchors.fill: parent
        active: introActive
        source: active ? "ui/components/IntroOverlay.qml" : ""

        onLoaded: {
            item.introActive = Qt.binding(function() { return root.introActive })
            item.finished.connect(root.finishIntro)
        }
        onStatusChanged: {
            if (status === Loader.Error) {
                root.finishIntro()
            }
        }
    }
}

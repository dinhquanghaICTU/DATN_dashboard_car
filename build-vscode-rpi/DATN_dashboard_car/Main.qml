import QtQuick 2.15
import QtQuick.Window 2.15
import "ui/components"

Window {
    id: root
    visible: true
    width: 800
    height: 480
    minimumWidth: 800
    maximumWidth: 800
    minimumHeight: 480
    maximumHeight: 480
    color: bgColor
    title: "DATN Dashboard"

    property bool introActive: true
    property int themeIndex: 0
    property string themeName: themeIndex === 0 ? "AQUA" : themeIndex === 1 ? "FOREST" : "AMBER"
    property color bgColor: themeIndex === 0 ? "#080c12" : themeIndex === 1 ? "#07100c" : "#100d08"
    property color primaryLine: themeIndex === 0 ? Qt.rgba(0, 0.9, 0.8, 0.12) : themeIndex === 1 ? Qt.rgba(0.35, 0.84, 0.55, 0.12) : Qt.rgba(1.0, 0.7, 0.28, 0.12)
    property color primaryBorder: themeIndex === 0 ? Qt.rgba(0, 0.9, 0.8, 0.15) : themeIndex === 1 ? Qt.rgba(0.35, 0.84, 0.55, 0.15) : Qt.rgba(1.0, 0.7, 0.28, 0.15)
    property color rpmBorder: themeIndex === 0 ? Qt.rgba(0.6, 0.4, 1, 0.2) : themeIndex === 1 ? Qt.rgba(0.49, 0.78, 1, 0.2) : Qt.rgba(1, 0.56, 0.44, 0.2)
    property color tempBorder: themeIndex === 0 ? Qt.rgba(1, 0.67, 0, 0.2) : themeIndex === 1 ? Qt.rgba(1, 0.82, 0.4, 0.2) : Qt.rgba(1, 0.62, 0.11, 0.2)
    property color accentBorder: themeIndex === 0 ? Qt.rgba(0, 1, 0.5, 0.2) : themeIndex === 1 ? Qt.rgba(0.72, 0.95, 0.78, 0.2) : Qt.rgba(1, 0.88, 0.48, 0.2)
    property color warningBorder: themeIndex === 0 ? Qt.rgba(1, 0.8, 0, 0.2) : themeIndex === 1 ? Qt.rgba(0.96, 0.82, 0.37, 0.2) : Qt.rgba(1, 0.8, 0.4, 0.2)
    property color primary: themeIndex === 0 ? "#00e5cc" : themeIndex === 1 ? "#58d68d" : "#ffb347"
    property color accent: themeIndex === 0 ? "#00ff88" : themeIndex === 1 ? "#b8f2c8" : "#ffe17a"
    property color speedColor: themeIndex === 0 ? "#00d4ff" : themeIndex === 1 ? "#7ee8a7" : "#ffc857"
    property color rpmColor: themeIndex === 0 ? "#9966ff" : themeIndex === 1 ? "#7cc7ff" : "#ff8f70"
    property color tempColor: themeIndex === 0 ? "#ffaa00" : themeIndex === 1 ? "#ffd166" : "#ff9f1c"
    property color warningColor: themeIndex === 0 ? "#ffcc00" : themeIndex === 1 ? "#f4d35e" : "#ffcc66"
    property color dangerColor: "#ff4444"
    property color displayTempColor: vehicle.temperature > 50.0 ? dangerColor : tempColor
    property color topPanelColor: themeIndex === 0 ? Qt.rgba(0, 0.55, 0.48, 0.35) : themeIndex === 1 ? Qt.rgba(0.18, 0.62, 0.32, 0.35) : Qt.rgba(0.85, 0.34, 0.05, 0.35)
    property color weatherPanelColor: themeIndex === 0 ? "#101827" : themeIndex === 1 ? "#10160f" : "#1f1208"
    property color rainColor: themeIndex === 0 ? "#ff4fd8" : themeIndex === 1 ? "#b36bff" : "#1f6fff"
    property color weatherIconColor: weatherMode === "sun" ? (themeIndex === 2 ? dangerColor : "#ffd21f") : weatherMode === "rain" ? rainColor : "#d8eef6"
    property string weatherMode: "sun"

    property bool themeReloading: false
    property int pendingThemeIndex: -1
    property bool leftSignal: ledCtrl.leftSignal
    property bool rightSignal: ledCtrl.rightSignal
    property bool headLight: ledCtrl.headLight
    property int signalTick: 0
    property real batteryLevel: 10.0
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
        if (index === themeIndex && !themeReloading) return
        pendingThemeIndex = index
        themeReloading = true
        themeApplyTimer.restart()
    }

    function nextTheme() {
        applyTheme((themeIndex + 1) % 3)
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

    Timer {
        id: themeApplyTimer
        interval: 35
        repeat: false
        onTriggered: {
            if (pendingThemeIndex >= 0) {
                themeIndex = pendingThemeIndex
                pendingThemeIndex = -1
            }
            themeRevealTimer.restart()
        }
    }

    Timer {
        id: themeRevealTimer
        interval: 90
        repeat: false
        onTriggered: themeReloading = false
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
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            introActive: root.introActive
            bgColor: root.bgColor
            primary: root.primary
            topPanelColor: root.topPanelColor
            weatherPanelColor: root.weatherPanelColor
            weatherMode: root.weatherMode
            weatherIconColor: root.weatherIconColor
        }

        Rectangle { x: 246; y: 52; width: 1; height: 390; color: primaryLine }
        Rectangle { x: parent.width - 247; y: 52; width: 1; height: 390; color: primaryLine }

        LeftDashboardPanel {
            x: 10; y: 52
            themeIndex: root.themeIndex
            themeName: root.themeName
            primary: root.primary
            accent: root.accent
            warningColor: root.warningColor
            dangerColor: root.dangerColor
            tempColor: root.tempColor
            displayTempColor: root.displayTempColor
            batteryLevel: root.batteryLevel
            batteryCriticalVisible: root.batteryCriticalVisible
            leftSignal: root.leftSignal
            rightSignal: root.rightSignal
            headLight: root.headLight
            signalTick: root.signalTick
            temperature: vehicle.temperature
            temperatureHazardLocked: root.temperatureHazardLocked
            onToggleLeftSignal: ledCtrl.toggleLeftSignal()
            onToggleRightSignal: ledCtrl.toggleRightSignal()
            onToggleHazard: ledCtrl.toggleHazard()
            onToggleHeadLight: ledCtrl.toggleHeadLight()
            onApplyTheme: function(index) { root.applyTheme(index) }
            onNextTheme: root.nextTheme()
        }

        CenterGaugePanel {
            x: 246; y: 48
            width: parent.width - 492
            height: 432
            introActive: root.introActive
            themeIndex: root.themeIndex
            primary: root.primary
            accent: root.accent
            warningColor: root.warningColor
            dangerColor: root.dangerColor
            bgColor: root.bgColor
            rpmColor: root.rpmColor
            displaySpeed: root.displaySpeed
            displaySpeedKmh: root.displaySpeedKmh
            displayRpm: root.displayRpm
        }

        RightStatsPanel {
            x: parent.width - 256; y: 52
            themeIndex: root.themeIndex
            primary: root.primary
            accent: root.accent
            speedColor: root.speedColor
            rpmColor: root.rpmColor
            tempColor: root.tempColor
            dangerColor: root.dangerColor
            warningColor: root.warningColor
            displayTempColor: root.displayTempColor
            primaryBorder: root.primaryBorder
            rpmBorder: root.rpmBorder
            tempBorder: root.tempBorder
            accentBorder: root.accentBorder
            warningBorder: root.warningBorder
            displaySpeedKmh: root.displaySpeedKmh
            displayRpm: root.displayRpm
            temperature: vehicle.temperature
            batteryLevel: root.batteryLevel
            batteryCriticalVisible: root.batteryCriticalVisible
        }
    }

    Rectangle {
        anchors.fill: parent
        z: 500
        visible: themeReloading && !introActive
        color: "black"
    }

    IntroOverlay {
        anchors.fill: parent
        introActive: root.introActive
        onFinished: root.finishIntro()
    }
}

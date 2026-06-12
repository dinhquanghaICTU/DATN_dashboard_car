import QtQuick 2.15

Item {
    id: root
    width: 246
    height: 400

    property int themeIndex: 0
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color speedColor: "#00d4ff"
    property color rpmColor: "#9966ff"
    property color tempColor: "#ffaa00"
    property color dangerColor: "#ff4444"
    property color warningColor: "#ffcc00"
    property color displayTempColor: tempColor
    property color primaryBorder: Qt.rgba(0, 0.9, 0.8, 0.15)
    property color rpmBorder: Qt.rgba(0.6, 0.4, 1, 0.2)
    property color tempBorder: Qt.rgba(1, 0.67, 0, 0.2)
    property color accentBorder: Qt.rgba(0, 1, 0.5, 0.2)
    property color warningBorder: Qt.rgba(1, 0.8, 0, 0.2)
    property real displaySpeedKmh: 0
    property real displayRpm: 0
    property real temperature: 0
    property real batteryLevel: 10.0
    property bool batteryCriticalVisible: true

    onThemeIndexChanged: repaint()
    onSpeedColorChanged: repaint()
    onRpmColorChanged: repaint()
    onDisplayTempColorChanged: repaint()
    onBatteryLevelChanged: repaint()

    function repaint() {
        speedCardIcon.requestPaint()
        rpmCardIcon.requestPaint()
        tempCardIcon.requestPaint()
        batteryCardIcon.requestPaint()
    }

    Column {
        x: 14; y: 8; spacing: 14

        Rectangle {
            width: 218; height: 72; radius: 12
            color: Qt.rgba(1, 1, 1, 0.04); border.color: root.primaryBorder; border.width: 1
            Row {
                x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                Canvas {
                    id: speedCardIcon
                    width: 32; height: 32; anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = root.speedColor; ctx.lineWidth = 2
                        ctx.beginPath(); ctx.arc(16, 20, 12, Math.PI * 0.8, Math.PI * 0.2); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(16, 20); ctx.lineTo(23, 12); ctx.stroke()
                        ctx.beginPath(); ctx.arc(16, 20, 2, 0, Math.PI * 2)
                        ctx.fillStyle = root.speedColor; ctx.fill()
                    }
                }
                Column {
                    spacing: 2; anchors.verticalCenter: parent.verticalCenter
                    Text { text: root.displaySpeedKmh.toFixed(2); color: root.speedColor; font.pixelSize: 26; font.bold: true; font.family: "Courier New" }
                    Text { text: "km/h  Speed"; color: Qt.rgba(1, 1, 1, 0.3); font.pixelSize: 10; font.family: "Courier New" }
                }
            }
        }

        Rectangle {
            width: 218; height: 72; radius: 12
            color: Qt.rgba(1, 1, 1, 0.04); border.color: root.rpmBorder; border.width: 1
            Row {
                x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                Canvas {
                    id: rpmCardIcon
                    width: 32; height: 32; anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = root.rpmColor; ctx.lineWidth = 2; ctx.lineCap = "round"
                        ctx.beginPath(); ctx.arc(16, 16, 12, Math.PI * 0.75, Math.PI * 2.25); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(16, 16); ctx.lineTo(24, 10)
                        ctx.strokeStyle = root.rpmColor; ctx.lineWidth = 2; ctx.stroke()
                    }
                }
                Column {
                    spacing: 2; anchors.verticalCenter: parent.verticalCenter
                    Text { text: root.displayRpm.toFixed(0); color: root.rpmColor; font.pixelSize: 26; font.bold: true; font.family: "Courier New" }
                    Text { text: "RPM"; color: Qt.rgba(1, 1, 1, 0.3); font.pixelSize: 10; font.family: "Courier New" }
                }
            }
        }

        Rectangle {
            width: 218; height: 72; radius: 12
            color: Qt.rgba(1, 1, 1, 0.04); border.color: root.tempBorder; border.width: 1
            Row {
                x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                Canvas {
                    id: tempCardIcon
                    width: 32; height: 40; anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                        var pct = Math.min(Math.max((root.temperature - 20) / 60, 0), 1)
                        var bars = Math.ceil(pct * 4)
                        for (var i = 0; i < 4; i++) {
                            var bh = 8 + i * 7; var bx = i * 8 + 2
                            ctx.fillStyle = i < bars ? root.displayTempColor : "rgba(255,255,255,0.1)"
                            ctx.fillRect(bx, 36 - bh, 6, bh)
                        }
                    }
                    property real tmp: root.temperature
                    onTmpChanged: requestPaint()
                }
                Column {
                    spacing: 2; anchors.verticalCenter: parent.verticalCenter
                    Text { text: root.temperature.toFixed(1) + "°C"; color: root.displayTempColor; font.pixelSize: 26; font.bold: true; font.family: "Courier New" }
                    Text { text: "Engine Temp"; color: Qt.rgba(1, 1, 1, 0.3); font.pixelSize: 10; font.family: "Courier New" }
                }
            }
        }

        Rectangle {
            width: 218; height: 72; radius: 12
            color: Qt.rgba(1, 1, 1, 0.04)
            border.color: root.batteryLevel > 50 ? root.accentBorder : root.batteryLevel > 20 ? root.warningBorder : Qt.rgba(1, 0.2, 0.2, 0.3)
            border.width: 1
            Row {
                x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                opacity: root.batteryCriticalVisible ? 1.0 : 0.2
                Canvas {
                    id: batteryCardIcon
                    width: 42; height: 22; anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                        var clr = root.batteryLevel > 50 ? root.accent : root.batteryLevel > 20 ? root.warningColor : root.dangerColor
                        ctx.strokeStyle = clr; ctx.lineWidth = 2
                        ctx.strokeRect(1, 1, 34, 20)
                        ctx.strokeRect(35, 6, 4, 10)
                        var fw = (root.batteryLevel / 100) * 30
                        ctx.fillStyle = clr
                        ctx.fillRect(3, 3, fw, 16)
                    }
                    property real batt: root.batteryLevel
                    onBattChanged: requestPaint()
                }
                Column {
                    spacing: 2; anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: root.batteryLevel.toFixed(0) + "%"
                        color: root.batteryLevel > 50 ? root.accent : root.batteryLevel > 20 ? root.warningColor : root.dangerColor
                        font.pixelSize: 26; font.bold: true; font.family: "Courier New"
                    }
                    Text { text: "Battery"; color: Qt.rgba(1, 1, 1, 0.3); font.pixelSize: 10; font.family: "Courier New" }
                }
            }
        }

        Column {
            x: 0; spacing: 8; width: 218

            Row { spacing: 8
                Text { width: 30; text: "TMP"; color: Qt.rgba(1, 1, 1, 0.25); font.pixelSize: 9; font.family: "Courier New"; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 180; height: 3; radius: 2; color: Qt.rgba(1, 1, 1, 0.08); anchors.verticalCenter: parent.verticalCenter
                    Rectangle { width: Math.min(Math.max((root.temperature - 20) / 60, 0), 1) * 180; height: 3; radius: 2; color: root.displayTempColor; Behavior on width { NumberAnimation { duration: 120 } } }
                }
            }
            Row { spacing: 8
                Text { width: 30; text: "BAT"; color: Qt.rgba(1, 1, 1, 0.25); font.pixelSize: 9; font.family: "Courier New"; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 180; height: 3; radius: 2; color: Qt.rgba(1, 1, 1, 0.08); anchors.verticalCenter: parent.verticalCenter
                    Rectangle { width: (root.batteryLevel / 100) * 180; height: 3; radius: 2; color: root.batteryLevel < 10.0 ? root.dangerColor : root.accent; opacity: root.batteryCriticalVisible ? 1.0 : 0.2; Behavior on width { NumberAnimation { duration: 120 } } }
                }
            }
        }
    }
}

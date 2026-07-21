import QtQuick 2.15

Item {
    id: root
    width: 308
    height: 432

    property bool introActive: false
    property int themeIndex: 0
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color warningColor: "#ffcc00"
    property color dangerColor: "#ff4444"
    property color bgColor: "#080c12"
    property color rpmColor: "#9966ff"
    property real displaySpeed: 0
    property real displaySpeedKmh: 0
    property real displayRpm: 0

    onThemeIndexChanged: repaint()
    onPrimaryChanged: repaint()
    onAccentChanged: repaint()
    onWarningColorChanged: repaint()
    onDangerColorChanged: repaint()
    onDisplaySpeedKmhChanged: speedGaugeCanvas.requestPaint()

    function repaint() {
        speedGaugeStaticCanvas.requestPaint()
        speedGaugeCanvas.requestPaint()
        movingCarIcon.requestPaint()
    }

    Canvas {
        id: speedGaugeStaticCanvas
        x: 10; y: 4; width: parent.width - 20; height: 280
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var cx = width / 2, cy = 172, r = 112
            var startA = Math.PI * 0.72
            ctx.beginPath(); ctx.arc(cx, cy, r, Math.PI * 0.72, Math.PI * 2.28)
            ctx.strokeStyle = "rgba(255,255,255,0.06)"; ctx.lineWidth = 18; ctx.lineCap = "round"; ctx.stroke()
            for (var i = 0; i <= 12; i++) {
                var a = startA + (i / 12) * Math.PI * 1.56
                ctx.strokeStyle = i % 4 === 0 ? "rgba(255,255,255,0.6)" : "rgba(255,255,255,0.2)"
                ctx.lineWidth = i % 4 === 0 ? 2.5 : 1.2
                var r1 = r + 12, r2 = i % 4 === 0 ? r + 30 : r + 22
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1)
                ctx.lineTo(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2)
                ctx.stroke()
            }
            ctx.fillStyle = "rgba(255,255,255,0.4)"; ctx.font = "12px Courier New"
            ctx.textAlign = "center"
            var labels = ["0", "", "", "", "40", "", "", "", "80", "", "", "", "120"]
            for (var j = 0; j <= 12; j++) {
                var la = startA + (j / 12) * Math.PI * 1.56
                var lx = cx + Math.cos(la) * (r + 42), ly = cy + Math.sin(la) * (r + 42)
                ctx.fillText(labels[j], lx, ly + 4)
            }
        }
    }

    Canvas {
        id: speedGaugeCanvas
        x: 10; y: 4; width: parent.width - 20; height: 280
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var cx = width / 2, cy = 172, r = 112
            var pct = Math.min(root.displaySpeedKmh / 120.0, 1.0)
            if (pct <= 0.001) return
            var startA = Math.PI * 0.72
            var endA = startA + pct * Math.PI * 1.56
            var grad = ctx.createLinearGradient(0, 0, width, 0)
            grad.addColorStop(0, root.primary); grad.addColorStop(0.5, root.accent); grad.addColorStop(1.0, root.warningColor)
            ctx.beginPath(); ctx.arc(cx, cy, r, startA, endA)
            ctx.strokeStyle = root.displaySpeedKmh >= 80.0 ? root.dangerColor : grad; ctx.lineWidth = 18; ctx.lineCap = "round"; ctx.stroke()
            var na = endA
            ctx.shadowColor = root.displaySpeedKmh >= 80.0 ? root.dangerColor : "#ffffff"; ctx.shadowBlur = 8
            ctx.beginPath(); ctx.arc(cx + Math.cos(na) * r, cy + Math.sin(na) * r, 7, 0, Math.PI * 2)
            ctx.fillStyle = root.displaySpeedKmh >= 80.0 ? root.dangerColor : "#ffffff"; ctx.fill(); ctx.shadowBlur = 0
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter; y: 100
        text: root.displaySpeedKmh.toFixed(1)
        color: "white"; font.pixelSize: 45; font.bold: true; font.family: "Courier New"
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter; y: 162
        text: "km/h"; color: root.primary; font.pixelSize: 17; font.family: "Courier New"; font.letterSpacing: 6
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter; y: 210
        text: root.displayRpm.toFixed(0)
        color: root.rpmColor; font.pixelSize: 50; font.bold: true; font.family: "Courier New"
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter; y: 284
        text: "RPM"; color: root.rpmColor; font.pixelSize: 17; font.family: "Courier New"; font.letterSpacing: 6; opacity: 0.7
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter; y: 312
        text: root.displaySpeed.toFixed(3) + " m/s"
        color: Qt.rgba(1, 1, 1, 0.2); font.pixelSize: 14; font.family: "Courier New"
    }

    Canvas {
        id: movingCarIcon
        anchors.horizontalCenter: parent.horizontalCenter
        y: 344
        width: 180; height: 48
        property int animTick: 0
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.10)
            ctx.lineWidth = 2
            ctx.beginPath(); ctx.moveTo(18, 38); ctx.lineTo(162, 38); ctx.stroke()

            ctx.strokeStyle = root.primary
            ctx.lineWidth = 2
            ctx.globalAlpha = 0.28
            for (var i = 0; i < 4; ++i) {
                var x = 18 + ((animTick * 6 + i * 42) % 132)
                ctx.beginPath(); ctx.moveTo(x, 33); ctx.lineTo(x - 22, 33); ctx.stroke()
            }
            ctx.globalAlpha = 1

            var carX = 58 + Math.sin(animTick * 0.22) * 4
            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.05)
            ctx.strokeStyle = root.primary
            ctx.lineWidth = 2.5
            ctx.beginPath()
            ctx.moveTo(carX + 8, 28)
            ctx.lineTo(carX + 22, 16)
            ctx.lineTo(carX + 58, 16)
            ctx.lineTo(carX + 74, 28)
            ctx.lineTo(carX + 88, 28)
            ctx.quadraticCurveTo(carX + 94, 28, carX + 94, 33)
            ctx.lineTo(carX + 2, 33)
            ctx.quadraticCurveTo(carX + 2, 28, carX + 8, 28)
            ctx.closePath()
            ctx.fill()
            ctx.stroke()

            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.18)
            ctx.beginPath()
            ctx.moveTo(carX + 28, 18)
            ctx.lineTo(carX + 39, 18)
            ctx.lineTo(carX + 39, 27)
            ctx.lineTo(carX + 19, 27)
            ctx.closePath()
            ctx.fill()
            ctx.beginPath()
            ctx.moveTo(carX + 43, 18)
            ctx.lineTo(carX + 56, 18)
            ctx.lineTo(carX + 67, 27)
            ctx.lineTo(carX + 43, 27)
            ctx.closePath()
            ctx.fill()

            ctx.fillStyle = root.accent
            ctx.beginPath(); ctx.arc(carX + 24, 34, 6, 0, Math.PI * 2); ctx.fill()
            ctx.beginPath(); ctx.arc(carX + 72, 34, 6, 0, Math.PI * 2); ctx.fill()
            ctx.fillStyle = root.bgColor
            ctx.beginPath(); ctx.arc(carX + 24, 34, 3, 0, Math.PI * 2); ctx.fill()
            ctx.beginPath(); ctx.arc(carX + 72, 34, 3, 0, Math.PI * 2); ctx.fill()

            ctx.fillStyle = root.displaySpeedKmh >= 80.0 ? root.dangerColor : root.warningColor
            ctx.beginPath(); ctx.moveTo(carX + 94, 29); ctx.lineTo(carX + 102, 31); ctx.lineTo(carX + 94, 33); ctx.closePath(); ctx.fill()
        }
        property int theme: root.themeIndex
        property real speedValue: root.displaySpeedKmh
        onThemeChanged: requestPaint()
        onSpeedValueChanged: requestPaint()
        Timer {
            interval: 90
            running: !root.introActive
            repeat: true
            onTriggered: {
                movingCarIcon.animTick = (movingCarIcon.animTick + 1) % 1000
                movingCarIcon.requestPaint()
            }
        }
    }
}

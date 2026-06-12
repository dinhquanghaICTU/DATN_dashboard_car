import QtQuick 2.15

Item {
    id: root
    width: 246
    height: 400

    property int themeIndex: 0
    property string themeName: "AQUA"
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color warningColor: "#ffcc00"
    property color dangerColor: "#ff4444"
    property color tempColor: "#ffaa00"
    property color displayTempColor: tempColor
    property real batteryLevel: 10.0
    property bool batteryCriticalVisible: true
    property bool leftSignal: false
    property bool rightSignal: false
    property bool headLight: false
    property int signalTick: 0
    property real temperature: 0
    property bool temperatureHazardLocked: false

    signal toggleLeftSignal()
    signal toggleRightSignal()
    signal toggleHazard()
    signal toggleHeadLight()
    signal applyTheme(int index)
    signal nextTheme()

    onThemeIndexChanged: repaint()
    onPrimaryChanged: repaint()
    onAccentChanged: repaint()
    onWarningColorChanged: repaint()
    onDangerColorChanged: repaint()
    onDisplayTempColorChanged: repaint()

    function repaint() {
        batteryArc.requestPaint()
        leftSignalIcon.requestPaint()
        hazardIcon.requestPaint()
        rightSignalIcon.requestPaint()
        lampIcon.requestPaint()
        tempIconSmall.requestPaint()
        tempBarsLeft.requestPaint()
    }

    Canvas {
        id: batteryArc
        x: 23; y: 8; width: 200; height: 200
        opacity: root.batteryCriticalVisible ? 1.0 : 0.2
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var cx = 100, cy = 100, r = 80
            ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI * 0.8, Math.PI * 0.8)
            ctx.strokeStyle = "rgba(255,255,255,0.07)"; ctx.lineWidth = 12; ctx.lineCap = "round"; ctx.stroke()
            var pct = root.batteryLevel / 100.0
            var grad = ctx.createLinearGradient(0, 0, 200, 0)
            if (root.batteryLevel > 50) { grad.addColorStop(0, root.primary); grad.addColorStop(1, root.accent) }
            else if (root.batteryLevel > 20) { grad.addColorStop(0, root.warningColor); grad.addColorStop(1, root.tempColor) }
            else { grad.addColorStop(0, root.dangerColor); grad.addColorStop(1, "#ff0000") }
            ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI * 0.8, -Math.PI * 0.8 + pct * Math.PI * 1.6)
            ctx.strokeStyle = grad; ctx.lineWidth = 12; ctx.lineCap = "round"; ctx.stroke()
        }
        property real batt: root.batteryLevel
        onBattChanged: requestPaint()
    }
    Text {
        x: 23; y: 80; width: 200
        text: root.batteryLevel.toFixed(0) + "%"
        color: root.batteryLevel > 50 ? root.primary : root.batteryLevel > 20 ? root.warningColor : root.dangerColor
        opacity: root.batteryCriticalVisible ? 1.0 : 0.2
        font.pixelSize: 34; font.bold: true; font.family: "Courier New"
        horizontalAlignment: Text.AlignHCenter
    }
    Text {
        x: 23; y: 122; width: 200
        text: "Battery"
        color: Qt.rgba(1, 1, 1, 0.35); font.pixelSize: 12; font.family: "Courier New"
        opacity: root.batteryCriticalVisible ? 1.0 : 0.2
        font.letterSpacing: 2; horizontalAlignment: Text.AlignHCenter
    }

    Rectangle { x: 20; y: 216; width: 206; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }

    Row {
        x: 16; y: 228; spacing: 10

        Canvas {
            id: leftSignalIcon
            width: 36; height: 36
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = (root.leftSignal && root.signalTick === 0) ? root.accent : "rgba(255,255,255,0.1)"
                ctx.beginPath(); ctx.moveTo(36, 6); ctx.lineTo(16, 18); ctx.lineTo(36, 30); ctx.closePath(); ctx.fill()
                ctx.beginPath(); ctx.moveTo(20, 6); ctx.lineTo(0, 18); ctx.lineTo(20, 30); ctx.closePath(); ctx.fill()
            }
            property bool ls: root.leftSignal; property int st: root.signalTick
            onLsChanged: requestPaint()
            onStChanged: requestPaint()
            MouseArea { anchors.fill: parent; enabled: !root.temperatureHazardLocked; onClicked: root.toggleLeftSignal() }
        }
        Canvas {
            id: hazardIcon
            width: 36; height: 36
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = (root.leftSignal && root.rightSignal) ? root.warningColor : "rgba(255,255,255,0.1)"
                ctx.beginPath(); ctx.moveTo(18, 2); ctx.lineTo(34, 32); ctx.lineTo(2, 32); ctx.closePath(); ctx.fill()
            }
            property bool ls: root.leftSignal; property bool rs: root.rightSignal
            onLsChanged: requestPaint()
            onRsChanged: requestPaint()
            MouseArea { anchors.fill: parent; enabled: !root.temperatureHazardLocked; onClicked: root.toggleHazard() }
        }
        Canvas {
            id: rightSignalIcon
            width: 36; height: 36
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = (root.rightSignal && root.signalTick === 0) ? root.accent : "rgba(255,255,255,0.1)"
                ctx.beginPath(); ctx.moveTo(0, 6); ctx.lineTo(20, 18); ctx.lineTo(0, 30); ctx.closePath(); ctx.fill()
                ctx.beginPath(); ctx.moveTo(14, 6); ctx.lineTo(34, 18); ctx.lineTo(14, 30); ctx.closePath(); ctx.fill()
            }
            property bool rs: root.rightSignal; property int st: root.signalTick
            onRsChanged: requestPaint()
            onStChanged: requestPaint()
            MouseArea { anchors.fill: parent; enabled: !root.temperatureHazardLocked; onClicked: root.toggleRightSignal() }
        }
        Canvas {
            id: lampIcon
            width: 36; height: 36
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = root.headLight ? root.accent : "rgba(255,255,255,0.15)"
                ctx.lineWidth = 2
                ctx.beginPath(); ctx.arc(18, 18, 9, 0, Math.PI * 2); ctx.stroke()
                for (var i = 0; i < 6; i++) {
                    var a = (i / 6) * Math.PI * 2
                    ctx.beginPath(); ctx.moveTo(18 + Math.cos(a) * 11, 18 + Math.sin(a) * 11)
                    ctx.lineTo(18 + Math.cos(a) * 16, 18 + Math.sin(a) * 16); ctx.stroke()
                }
            }
            property bool hl: root.headLight
            onHlChanged: requestPaint()
            MouseArea { anchors.fill: parent; enabled: !root.temperatureHazardLocked; onClicked: root.toggleHeadLight() }
        }
        Canvas {
            id: tempIconSmall
            width: 36; height: 36
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = root.displayTempColor; ctx.lineWidth = 2
                ctx.beginPath(); ctx.moveTo(14, 4); ctx.lineTo(14, 26); ctx.stroke()
                ctx.beginPath(); ctx.moveTo(22, 4); ctx.lineTo(22, 26); ctx.stroke()
                ctx.beginPath(); ctx.moveTo(14, 4); ctx.arc(18, 4, 4, -Math.PI, 0); ctx.stroke()
                ctx.beginPath(); ctx.arc(18, 30, 6, 0, Math.PI * 2)
                ctx.fillStyle = root.displayTempColor; ctx.fill()
                var pct = Math.min(Math.max((root.temperature - 20) / 60, 0), 1)
                ctx.fillStyle = root.displayTempColor
                ctx.fillRect(15, 26 - pct * 20, 6, pct * 20)
            }
            property real tmp: root.temperature
            onTmpChanged: requestPaint()
        }
    }

    Row {
        x: 16; y: 270; spacing: 10
        Text { width: 36; text: "L"; color: Qt.rgba(1, 1, 1, 0.2); font.pixelSize: 9; font.family: "Courier New"; horizontalAlignment: Text.AlignHCenter }
        Text { width: 36; text: "HAZ"; color: Qt.rgba(1, 1, 1, 0.2); font.pixelSize: 9; font.family: "Courier New"; horizontalAlignment: Text.AlignHCenter }
        Text { width: 36; text: "R"; color: Qt.rgba(1, 1, 1, 0.2); font.pixelSize: 9; font.family: "Courier New"; horizontalAlignment: Text.AlignHCenter }
        Text { width: 36; text: "LAMP"; color: Qt.rgba(1, 1, 1, 0.2); font.pixelSize: 9; font.family: "Courier New"; horizontalAlignment: Text.AlignHCenter }
        Text { width: 36; text: "TEMP"; color: Qt.rgba(1, 1, 1, 0.2); font.pixelSize: 9; font.family: "Courier New"; horizontalAlignment: Text.AlignHCenter }
    }

    Row {
        x: 14; y: 284; spacing: 8
        Repeater {
            model: 3
            Item {
                width: 36; height: 36
                Rectangle {
                    anchors.centerIn: parent
                    width: root.themeIndex === index ? 32 : 28
                    height: width
                    radius: width / 2
                    color: index === 0 ? "#00e5cc" : index === 1 ? "#58d68d" : "#ffb347"
                    border.color: root.themeIndex === index ? "white" : Qt.rgba(1, 1, 1, 0.18)
                    border.width: root.themeIndex === index ? 3 : 1
                    Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.applyTheme(index)
                }
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.themeName
            color: Qt.rgba(1, 1, 1, 0.38)
            font.pixelSize: 14; font.family: "Courier New"; font.bold: true; font.letterSpacing: 2
            Behavior on color { ColorAnimation { duration: 120 } }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -10
                onClicked: root.nextTheme()
            }
        }
    }

    Row {
        x: 14; y: 338; spacing: 10
        Canvas {
            id: tempBarsLeft
            width: 28; height: 40
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                var pct = Math.min(Math.max((root.temperature - 20) / 60, 0), 1)
                var bars = Math.ceil(pct * 4)
                for (var i = 0; i < 4; i++) {
                    var bh = 6 + i * 6; var bx = i * 7
                    ctx.fillStyle = i < bars ? root.displayTempColor : "rgba(255,255,255,0.1)"
                    ctx.fillRect(bx, 34 - bh, 5, bh)
                }
            }
            property real tmp: root.temperature
            onTmpChanged: requestPaint()
        }
        Column {
            spacing: 2
            Text { text: root.temperature.toFixed(1) + "°C"; color: root.displayTempColor; font.pixelSize: 22; font.bold: true; font.family: "Courier New" }
            Text { text: "Engine Temp"; color: Qt.rgba(1, 1, 1, 0.3); font.pixelSize: 10; font.family: "Courier New" }
        }
    }
}

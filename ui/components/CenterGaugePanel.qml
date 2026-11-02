import QtQuick 2.15

Item {
    id: root
    width: 312
    height: 290

    property bool introActive: false
    property int themeIndex: 0
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color warningColor: "#ffcc00"
    property color dangerColor: "#ff4444"
    property color bgColor: "#060a10"
    property color rpmColor: "#9966ff"
    property real displaySpeed: 0
    property real displaySpeedKmh: 0
    property real displayRpm: 0
    property bool leftSignal: false
    property bool rightSignal: false
    property int signalTick: 0
    property bool temperatureHazardLocked: false

    readonly property string fontFamily: "DejaVu Sans"
    readonly property real maxSpeed: 120
    readonly property real dangerSpeed: 80
    readonly property bool overSpeed: displaySpeedKmh >= dangerSpeed
    // Gauge geometry (shared by both canvases)
    readonly property real gcx: 156
    readonly property real gcy: 148
    readonly property real gr: 98

    onThemeIndexChanged: repaint()
    onPrimaryChanged: repaint()
    onAccentChanged: repaint()
    onDangerColorChanged: repaint()
    onDisplaySpeedKmhChanged: gaugeCanvas.requestPaint()

    function repaint() {
        gaugeStatic.requestPaint()
        gaugeCanvas.requestPaint()
    }

    function angleFor(v) {
        return Math.PI * 0.75 + Math.min(Math.max(v / maxSpeed, 0), 1) * Math.PI * 1.5
    }

    // --------------------------------------------------------- Gauge (static)
    Canvas {
        id: gaugeStatic
        width: parent.width; height: 262
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var cx = root.gcx, cy = root.gcy, r = root.gr

            // soft glow behind the dial
            var glow = ctx.createRadialGradient(cx, cy, 0, cx, cy, r + 30)
            glow.addColorStop(0, Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.13))
            glow.addColorStop(1, Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.0))
            ctx.fillStyle = glow
            ctx.beginPath(); ctx.arc(cx, cy, r + 30, 0, Math.PI * 2); ctx.fill()

            // inner disc
            ctx.beginPath(); ctx.arc(cx, cy, r - 16, 0, Math.PI * 2)
            ctx.fillStyle = "rgba(255,255,255,0.025)"; ctx.fill()
            ctx.strokeStyle = "rgba(255,255,255,0.06)"; ctx.lineWidth = 1; ctx.stroke()

            // track
            ctx.lineCap = "round"
            ctx.beginPath(); ctx.arc(cx, cy, r, root.angleFor(0), root.angleFor(root.maxSpeed))
            ctx.strokeStyle = "rgba(255,255,255,0.07)"; ctx.lineWidth = 12; ctx.stroke()

            // red zone
            ctx.lineCap = "butt"
            ctx.beginPath(); ctx.arc(cx, cy, r + 12, root.angleFor(root.dangerSpeed), root.angleFor(root.maxSpeed))
            ctx.strokeStyle = Qt.rgba(root.dangerColor.r, root.dangerColor.g, root.dangerColor.b, 0.75)
            ctx.lineWidth = 2; ctx.stroke()

            // ticks
            for (var v = 0; v <= root.maxSpeed; v += 5) {
                var a = root.angleFor(v)
                var major = v % 20 === 0, mid = v % 10 === 0
                var r1 = r + 15
                var r2 = major ? r + 26 : mid ? r + 21 : r + 18
                var danger = v >= root.dangerSpeed
                ctx.strokeStyle = danger ? root.dangerColor
                                 : major ? "rgba(255,255,255,0.75)" : mid ? "rgba(255,255,255,0.35)" : "rgba(255,255,255,0.18)"
                ctx.lineWidth = major ? 2.2 : 1.2
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1)
                ctx.lineTo(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2)
                ctx.stroke()
            }

            // labels
            ctx.font = "bold 11px \"DejaVu Sans\""
            ctx.textAlign = "center"; ctx.textBaseline = "middle"
            for (var s = 0; s <= root.maxSpeed; s += 20) {
                var la = root.angleFor(s)
                var lr = r + 38
                ctx.fillStyle = s >= root.dangerSpeed ? root.dangerColor : "rgba(255,255,255,0.55)"
                ctx.fillText(String(s), cx + Math.cos(la) * lr, cy + Math.sin(la) * lr)
            }
        }
    }

    // -------------------------------------------------------- Gauge (dynamic)
    Canvas {
        id: gaugeCanvas
        width: parent.width; height: 262
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var cx = root.gcx, cy = root.gcy, r = root.gr
            var pct = Math.min(root.displaySpeedKmh / root.maxSpeed, 1.0)
            if (pct <= 0.001) return
            var startA = root.angleFor(0)
            var endA = root.angleFor(root.displaySpeedKmh)
            var stroke
            if (root.overSpeed) {
                stroke = root.dangerColor
            } else {
                stroke = ctx.createLinearGradient(cx - r, 0, cx + r, 0)
                stroke.addColorStop(0, root.primary)
                stroke.addColorStop(1, root.accent)
            }
            var glowColor = root.overSpeed ? root.dangerColor : root.primary
            ctx.lineCap = "round"
            ctx.shadowColor = glowColor; ctx.shadowBlur = 14
            ctx.beginPath(); ctx.arc(cx, cy, r, startA, endA)
            ctx.strokeStyle = stroke; ctx.lineWidth = 12; ctx.stroke()

            // tip
            ctx.shadowColor = glowColor; ctx.shadowBlur = 10
            ctx.beginPath(); ctx.arc(cx + Math.cos(endA) * r, cy + Math.sin(endA) * r, 6.5, 0, Math.PI * 2)
            ctx.fillStyle = "#ffffff"; ctx.fill()
            ctx.shadowBlur = 0
        }
    }

    // ------------------------------------------------------- Speed readout
    Item {
        x: root.gcx; y: root.gcy
        Row {
            id: speedRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top; anchors.bottomMargin: -14
            Text {
                id: speedInt
                text: Math.floor(root.displaySpeedKmh).toString()
                color: root.overSpeed ? root.dangerColor : "white"
                font.family: root.fontFamily; font.pixelSize: 58; font.bold: true
            }
            Text {
                anchors.baseline: speedInt.baseline
                text: "." + Math.floor((root.displaySpeedKmh % 1) * 10)
                color: Qt.rgba(1, 1, 1, 0.45)
                font.family: root.fontFamily; font.pixelSize: 24; font.bold: true
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: speedRow.bottom; anchors.topMargin: -4
            text: "KM/H"
            color: root.primary
            font.family: root.fontFamily; font.pixelSize: 12; font.bold: true; font.letterSpacing: 4
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 46
            width: rpmRow.width + 28; height: 30; radius: 15
            color: Qt.rgba(root.rpmColor.r, root.rpmColor.g, root.rpmColor.b, 0.12)
            border.width: 1
            border.color: Qt.rgba(root.rpmColor.r, root.rpmColor.g, root.rpmColor.b, 0.45)
            Row {
                id: rpmRow
                anchors.centerIn: parent; spacing: 6
                Text {
                    id: rpmValue
                    text: root.displayRpm.toFixed(0)
                    color: root.rpmColor
                    font.family: root.fontFamily; font.pixelSize: 16; font.bold: true
                }
                Text {
                    anchors.baseline: rpmValue.baseline
                    text: "RPM"
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.family: root.fontFamily; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.5
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 86
            text: root.displaySpeed.toFixed(3) + " m/s"
            color: Qt.rgba(1, 1, 1, 0.4)
            font.family: root.fontFamily; font.pixelSize: 11; font.bold: true
        }
    }

    // ------------------------------------------------------- Turn signals
    Repeater {
        model: 2
        Canvas {
            id: arrow
            width: 34; height: 26
            x: index === 0 ? 4 : root.width - width - 4
            y: 4
            property bool active: index === 0 ? root.leftSignal : root.rightSignal
            property bool lit: active && root.signalTick === 0
            property color tone: root.accent
            onLitChanged: requestPaint()
            onActiveChanged: requestPaint()
            onToneChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                ctx.save()
                if (index === 1) { ctx.translate(width, 0); ctx.scale(-1, 1) }
                ctx.fillStyle = lit ? tone : active ? Qt.rgba(tone.r, tone.g, tone.b, 0.25) : "rgba(255,255,255,0.08)"
                ctx.beginPath()
                ctx.moveTo(3, 13); ctx.lineTo(15, 2); ctx.lineTo(15, 8); ctx.lineTo(31, 8)
                ctx.lineTo(31, 18); ctx.lineTo(15, 18); ctx.lineTo(15, 24); ctx.closePath()
                ctx.fill()
                ctx.restore()
            }
        }
    }

    // --------------------------------------------------------- Status banner
    Rectangle {
        id: banner
        readonly property int level: root.temperatureHazardLocked ? 2 : root.overSpeed ? 1 : 0
        readonly property color tone: level === 2 ? root.dangerColor : level === 1 ? root.warningColor : root.primary
        anchors.horizontalCenter: parent.horizontalCenter
        y: 258
        width: 252; height: 30; radius: 15
        color: level > 0 ? Qt.rgba(tone.r, tone.g, tone.b, 0.14) : Qt.rgba(1, 1, 1, 0.03)
        border.width: 1
        border.color: level > 0 ? Qt.rgba(tone.r, tone.g, tone.b, 0.6) : Qt.rgba(1, 1, 1, 0.08)

        Row {
            anchors.centerIn: parent; spacing: 8
            Rectangle {
                width: 8; height: 8; radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: banner.tone
                SequentialAnimation on opacity {
                    running: banner.level > 0 && !root.introActive
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) parent.opacity = 1
                    NumberAnimation { to: 0.2; duration: 450 }
                    NumberAnimation { to: 1.0; duration: 450 }
                }
            }
            Text {
                text: banner.level === 2 ? "ENGINE OVERHEAT · HAZARD ON"
                    : banner.level === 1 ? "OVER SPEED · SLOW DOWN"
                    : "ALL SYSTEMS NORMAL"
                color: banner.level > 0 ? banner.tone : Qt.rgba(1, 1, 1, 0.55)
                font.family: root.fontFamily; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.4
            }
        }
    }
}

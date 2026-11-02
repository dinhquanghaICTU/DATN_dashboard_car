import QtQuick 2.15

// Simulated navigation map. The car moves along a fixed route at a rate
// proportional to the measured vehicle speed.
DashCard {
    id: root
    width: 220
    height: 406
    color: Qt.rgba(1, 1, 1, 0.02)
    border.color: Qt.rgba(primary.r, primary.g, primary.b, 0.45)

    property bool introActive: false
    property int themeIndex: 0
    property color bgColor: "#060a10"
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color dangerColor: "#ff4444"
    property real displaySpeedKmh: 0

    readonly property string fontFamily: "DejaVu Sans"

    // Map geometry (in un-rotated "street grid" coordinates)
    readonly property real mapAngle: -14 * Math.PI / 180
    readonly property real mapCx: width / 2
    readonly property real mapCy: height / 2
    readonly property var streetsX: [-110, -40, 30, 100, 170, 240, 310]
    readonly property var streetsY: [-60, 30, 100, 170, 225, 280, 330, 400, 470]
    readonly property real mainStreetX: 100
    readonly property real mainStreetY: 170
    readonly property var route: [[30, 330], [30, 280], [100, 280], [100, 170], [170, 170], [170, 100]]
    readonly property real routeKm: 2.8
    readonly property real simFactor: 4.0       // speeds the simulation up so movement is visible

    property real progress: 0.42                // 0..1 along the route
    readonly property real remainingKm: routeKm * (1 - progress)
    readonly property real etaMin: displaySpeedKmh > 0.5 ? remainingKm / displaySpeedKmh * 60 : -1

    onThemeIndexChanged: { mapStatic.requestPaint(); mapDynamic.requestPaint() }
    onPrimaryChanged: { mapStatic.requestPaint(); mapDynamic.requestPaint() }
    onProgressChanged: mapDynamic.requestPaint()

    function routeLength() {
        var len = 0
        for (var i = 1; i < route.length; ++i)
            len += Math.abs(route[i][0] - route[i - 1][0]) + Math.abs(route[i][1] - route[i - 1][1])
        return len
    }

    // Returns {x, y, angle, seg} for a distance along the route.
    function pointAt(dist) {
        for (var i = 1; i < route.length; ++i) {
            var ax = route[i - 1][0], ay = route[i - 1][1], bx = route[i][0], by = route[i][1]
            var segLen = Math.abs(bx - ax) + Math.abs(by - ay)
            if (dist <= segLen || i === route.length - 1) {
                var t = segLen > 0 ? Math.min(dist / segLen, 1) : 0
                return { x: ax + (bx - ax) * t, y: ay + (by - ay) * t, angle: Math.atan2(by - ay, bx - ax), seg: i }
            }
            dist -= segLen
        }
        return { x: route[0][0], y: route[0][1], angle: 0, seg: 1 }
    }

    // Grid coordinates -> screen coordinates
    function toScreen(x, y) {
        var dx = x - mapCx, dy = y - mapCy
        var c = Math.cos(mapAngle), s = Math.sin(mapAngle)
        return { x: mapCx + dx * c - dy * s, y: mapCy + dx * s + dy * c }
    }

    function applyMapTransform(ctx) {
        ctx.beginPath(); ctx.roundedRect(1, 1, width - 2, height - 2, root.radius - 1, root.radius - 1); ctx.clip()
        ctx.translate(mapCx, mapCy); ctx.rotate(mapAngle); ctx.translate(-mapCx, -mapCy)
    }

    Timer {
        interval: 100
        repeat: true
        running: !root.introActive && root.displaySpeedKmh > 0.05
        onTriggered: {
            var step = root.displaySpeedKmh / 3600 * 0.1 * root.simFactor / root.routeKm
            var p = root.progress + step
            root.progress = p >= 1 ? 0 : p
        }
    }

    // ------------------------------------------------------------ Static map
    Canvas {
        id: mapStatic
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.save()
            root.applyMapTransform(ctx)
            var p = root.primary
            var xs = root.streetsX, ys = root.streetsY

            // blocks / buildings
            for (var i = 0; i < xs.length - 1; ++i) {
                for (var j = 0; j < ys.length - 1; ++j) {
                    var bx = xs[i] + 7, by = ys[j] + 7
                    var bw = xs[i + 1] - xs[i] - 14, bh = ys[j + 1] - ys[j] - 14
                    if (i === 1 && j === 2) {
                        ctx.fillStyle = "rgba(60,200,120,0.10)"      // park
                        ctx.fillRect(bx, by, bw, bh)
                        continue
                    }
                    ctx.fillStyle = "rgba(255,255,255,0.028)"
                    ctx.fillRect(bx, by, bw, bh)
                    if ((i * 7 + j * 13) % 3 === 0) {
                        ctx.fillStyle = "rgba(255,255,255,0.045)"
                        ctx.fillRect(bx + 6, by + 6, bw * 0.45, bh * 0.5)
                    }
                }
            }

            // river
            ctx.strokeStyle = "rgba(40,120,230,0.38)"; ctx.lineWidth = 16; ctx.lineCap = "round"
            ctx.beginPath(); ctx.moveTo(240, -80)
            ctx.bezierCurveTo(190, 60, 255, 200, 210, 300)
            ctx.bezierCurveTo(175, 370, 235, 430, 215, 520)
            ctx.stroke()

            // streets
            ctx.lineCap = "butt"
            for (var a = 0; a < xs.length; ++a) {
                var mainX = xs[a] === root.mainStreetX
                ctx.strokeStyle = Qt.rgba(p.r, p.g, p.b, mainX ? 0.17 : 0.09)
                ctx.lineWidth = mainX ? 10 : 6
                ctx.beginPath(); ctx.moveTo(xs[a], -200); ctx.lineTo(xs[a], 650); ctx.stroke()
            }
            for (var b = 0; b < ys.length; ++b) {
                var mainY = ys[b] === root.mainStreetY
                ctx.strokeStyle = Qt.rgba(p.r, p.g, p.b, mainY ? 0.17 : 0.09)
                ctx.lineWidth = mainY ? 10 : 6
                ctx.beginPath(); ctx.moveTo(-250, ys[b]); ctx.lineTo(450, ys[b]); ctx.stroke()
            }
            ctx.restore()

            // vignette so the chips stay readable
            var fade = ctx.createLinearGradient(0, 0, 0, height)
            fade.addColorStop(0, Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 0.55))
            fade.addColorStop(0.18, Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 0.0))
            fade.addColorStop(0.82, Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 0.0))
            fade.addColorStop(1, Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 0.55))
            ctx.fillStyle = fade
            ctx.beginPath(); ctx.roundedRect(1, 1, width - 2, height - 2, root.radius - 1, root.radius - 1); ctx.fill()
        }
    }

    // ------------------------------------------------- Route, car and markers
    Canvas {
        id: mapDynamic
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var p = root.primary
            var r = root.route
            var total = root.routeLength()
            var car = root.pointAt(root.progress * total)

            ctx.save()
            root.applyMapTransform(ctx)
            ctx.lineJoin = "round"; ctx.lineCap = "round"

            // travelled part (dim)
            ctx.strokeStyle = Qt.rgba(p.r, p.g, p.b, 0.28); ctx.lineWidth = 4
            ctx.beginPath(); ctx.moveTo(r[0][0], r[0][1])
            for (var i = 1; i < car.seg; ++i) ctx.lineTo(r[i][0], r[i][1])
            ctx.lineTo(car.x, car.y); ctx.stroke()

            // remaining part (bright, glowing)
            ctx.shadowColor = p; ctx.shadowBlur = 10
            ctx.strokeStyle = p; ctx.lineWidth = 5
            ctx.beginPath(); ctx.moveTo(car.x, car.y)
            for (var k = car.seg; k < r.length; ++k) ctx.lineTo(r[k][0], r[k][1])
            ctx.stroke()
            ctx.shadowBlur = 0

            // start marker
            ctx.beginPath(); ctx.arc(r[0][0], r[0][1], 7, 0, Math.PI * 2)
            ctx.fillStyle = root.bgColor; ctx.fill()
            ctx.strokeStyle = "white"; ctx.lineWidth = 3; ctx.stroke()

            // car
            ctx.translate(car.x, car.y)
            ctx.rotate(car.angle + Math.PI / 2)
            ctx.shadowColor = p; ctx.shadowBlur = 12
            ctx.fillStyle = "white"
            ctx.beginPath(); ctx.roundedRect(-7, -11, 14, 22, 5, 5); ctx.fill()
            ctx.shadowBlur = 0
            ctx.fillStyle = root.bgColor
            ctx.beginPath(); ctx.roundedRect(-5, -7, 10, 5, 2, 2); ctx.fill()
            ctx.beginPath(); ctx.roundedRect(-5, 4, 10, 4, 2, 2); ctx.fill()
            ctx.restore()

            // destination pin (kept upright)
            var end = root.toScreen(r[r.length - 1][0], r[r.length - 1][1])
            var d = root.dangerColor
            ctx.save()
            ctx.translate(end.x, end.y)
            ctx.shadowColor = d; ctx.shadowBlur = 12
            ctx.fillStyle = d
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.bezierCurveTo(-4, -8, -11, -12, -11, -21)
            ctx.arc(0, -21, 11, Math.PI, 0, false)
            ctx.bezierCurveTo(11, -12, 4, -8, 0, 0)
            ctx.closePath(); ctx.fill()
            ctx.shadowBlur = 0
            ctx.fillStyle = "white"
            ctx.beginPath(); ctx.arc(0, -21, 4.5, 0, Math.PI * 2); ctx.fill()
            ctx.restore()
        }
    }

    // ------------------------------------------------------------- Overlays
    Rectangle {
        id: speedChip
        x: 10; y: 10
        width: speedRow.width + 20; height: 40; radius: 12
        color: Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 0.85)
        border.width: 1
        border.color: Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.4)
        Row {
            id: speedRow
            anchors.centerIn: parent; spacing: 7
            Canvas {
                width: 16; height: 16
                anchors.verticalCenter: parent.verticalCenter
                property color tone: root.primary
                onToneChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = tone
                    ctx.beginPath(); ctx.moveTo(15, 1); ctx.lineTo(1, 7); ctx.lineTo(8, 8); ctx.lineTo(9, 15); ctx.closePath(); ctx.fill()
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Row {
                    Text {
                        id: chipSpeed
                        text: root.displaySpeedKmh.toFixed(1)
                        color: root.primary
                        font.family: root.fontFamily; font.pixelSize: 15; font.bold: true
                    }
                    Text {
                        anchors.baseline: chipSpeed.baseline
                        text: " km/h"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.family: root.fontFamily; font.pixelSize: 8; font.bold: true
                    }
                }
                Text {
                    text: "SPEED"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: root.fontFamily; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1.2
                }
            }
        }
    }

    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 10; y: 10
        width: distRow.width + 18; height: 40; radius: 12
        color: Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 0.85)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.14)
        Row {
            id: distRow
            anchors.centerIn: parent; spacing: 5
            Canvas {
                width: 10; height: 14
                anchors.verticalCenter: parent.verticalCenter
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = "white"
                    ctx.beginPath(); ctx.moveTo(5, 14); ctx.bezierCurveTo(2, 9, 0, 7.5, 0, 5)
                    ctx.arc(5, 5, 5, Math.PI, 0, false); ctx.bezierCurveTo(10, 7.5, 8, 9, 5, 14); ctx.fill()
                    ctx.fillStyle = "black"
                    ctx.beginPath(); ctx.arc(5, 5, 2, 0, Math.PI * 2); ctx.fill()
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.remainingKm.toFixed(1) + " km"
                color: "white"
                font.family: root.fontFamily; font.pixelSize: 13; font.bold: true
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 10
        width: etaRow.width + 24; height: 28; radius: 14
        color: Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 0.85)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.14)
        Row {
            id: etaRow
            anchors.centerIn: parent; spacing: 6
            Text {
                text: "ETA"
                color: root.primary
                font.family: root.fontFamily; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.4
            }
            Text {
                text: root.etaMin < 0 ? "--" : root.etaMin < 1 ? "< 1 min" : Math.round(root.etaMin) + " min"
                color: "white"
                font.family: root.fontFamily; font.pixelSize: 10; font.bold: true
            }
            Text {
                text: "· SIMULATED"
                color: Qt.rgba(1, 1, 1, 0.35)
                font.family: root.fontFamily; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1
            }
        }
    }
}

import QtQuick 2.15

Item {
    id: root
    width: 224
    height: 416

    property int themeIndex: 0
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color cardBg: "#080d16"
    property color cardBorder: Qt.rgba(0, 229, 204, 0.28)
    property color dangerColor: "#ff4444"
    property color warningColor: "#ffcc00"
    property real displaySpeedKmh: 45.0
    property real tripDistanceKm: 1.5

    onThemeIndexChanged: map3dCanvas.requestPaint()
    onPrimaryChanged: map3dCanvas.requestPaint()
    onAccentChanged: map3dCanvas.requestPaint()

    property real camZoom: 1.0

    property real camPitchBias: 0.0

    property real carWorldX: -45.0
    property real carWorldZ: 30.0
    property real carHeading: 0.0
    property real roadScroll: 0.0

    onCamZoomChanged: map3dCanvas.requestPaint()
    onCamPitchBiasChanged: map3dCanvas.requestPaint()
    onCarWorldXChanged: map3dCanvas.requestPaint()
    onCarWorldZChanged: map3dCanvas.requestPaint()
    onCarHeadingChanged: map3dCanvas.requestPaint()
    onRoadScrollChanged: map3dCanvas.requestPaint()

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: root.cardBg
        border.color: root.cardBorder
        border.width: 1.5
        clip: true

        Row {
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            spacing: 8
            z: 20

            Rectangle {
                width: Math.floor((parent.width - 8) * 0.55)
                height: 38
                radius: 8
                color: root.cardBg
                border.color: root.cardBorder
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "↗"
                        color: root.primary
                        font.pixelSize: 14
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0
                        Row {
                            spacing: 2
                            Text {
                                text: root.displaySpeedKmh.toFixed(1)
                                color: root.primary
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "Courier New"
                            }
                            Text {
                                text: "km/h"
                                color: Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.8)
                                font.pixelSize: 8
                                font.family: "Courier New"
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 1
                            }
                        }
                        Text {
                            text: "SPEED"
                            color: Qt.rgba(1, 1, 1, 0.4)
                            font.pixelSize: 7
                            font.bold: true
                            font.family: "Courier New"
                            font.letterSpacing: 1
                        }
                    }
                }
            }

            Rectangle {
                width: Math.floor((parent.width - 8) * 0.45)
                height: 38
                radius: 8
                color: root.cardBg
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "📍"
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.tripDistanceKm.toFixed(1) + " km"
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.bold: true
                        font.family: "Courier New"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        Canvas {
            id: map3dCanvas
            anchors.fill: parent
            z: 5

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var vp_x = width / 2.0
                var horizon_y = 65.0
                var ground_bottom_y = 372.0

                function project(wx, wz, wy) {
                    if (wy === undefined) wy = 0
                    var z_norm = Math.max(0.0, Math.min(wz / 300.0, 0.98))
                    var power = 0.65 + root.camPitchBias * 0.16
                    var t = Math.pow(z_norm, power)
                    var sy = ground_bottom_y - (ground_bottom_y - horizon_y) * t - wy * (1.0 - t * 0.8) * root.camZoom
                    var scale = (1.0 - t * 0.76) * root.camZoom
                    var sx = vp_x + wx * scale
                    return { x: sx, y: sy, scale: scale }
                }

                var horizGrad = ctx.createLinearGradient(0, horizon_y - 25, 0, horizon_y + 15)
                horizGrad.addColorStop(0.0, "rgba(8, 13, 22, 0.0)")
                horizGrad.addColorStop(0.5, "rgba(" + Math.round(root.primary.r * 255 * 0.2) + "," + Math.round(root.primary.g * 255 * 0.5) + "," + Math.round(root.primary.b * 255 * 0.6) + ", 0.35)")
                horizGrad.addColorStop(1.0, "rgba(8, 13, 22, 0.0)")
                ctx.fillStyle = horizGrad
                ctx.fillRect(0, horizon_y - 25, width, 40)

                ctx.strokeStyle = "rgba(22, 36, 56, 0.75)"
                ctx.lineWidth = 1
                for (var gz = 10; gz <= 290; gz += 28) {
                    var pGridL = project(-115, gz, 0)
                    var pGridR = project(115, gz, 0)
                    ctx.beginPath()
                    ctx.moveTo(pGridL.x, pGridL.y)
                    ctx.lineTo(pGridR.x, pGridR.y)
                    ctx.stroke()
                }
                for (var gx = -110; gx <= 110; gx += 22) {
                    var pGridB = project(gx, 0, 0)
                    var pGridT = project(gx, 290, 0)
                    ctx.beginPath()
                    ctx.moveTo(pGridB.x, pGridB.y)
                    ctx.lineTo(pGridT.x, pGridT.y)
                    ctx.stroke()
                }

                var av1_b1 = project(-62, 0, 0), av1_b2 = project(-28, 0, 0)
                var av1_t2 = project(-28, 290, 0), av1_t1 = project(-62, 290, 0)
                ctx.fillStyle = "#111b2b"
                ctx.beginPath()
                ctx.moveTo(av1_b1.x, av1_b1.y); ctx.lineTo(av1_b2.x, av1_b2.y)
                ctx.lineTo(av1_t2.x, av1_t2.y); ctx.lineTo(av1_t1.x, av1_t1.y)
                ctx.closePath(); ctx.fill()

                var av2_b1 = project(28, 0, 0), av2_b2 = project(62, 0, 0)
                var av2_t2 = project(62, 290, 0), av2_t1 = project(28, 290, 0)
                ctx.beginPath()
                ctx.moveTo(av2_b1.x, av2_b1.y); ctx.lineTo(av2_b2.x, av2_b2.y)
                ctx.lineTo(av2_t2.x, av2_t2.y); ctx.lineTo(av2_t1.x, av2_t1.y)
                ctx.closePath(); ctx.fill()

                var cr_l1 = project(-115, 134, 0), cr_r1 = project(115, 134, 0)
                var cr_r2 = project(115, 160, 0), cr_l2 = project(-115, 160, 0)
                ctx.beginPath()
                ctx.moveTo(cr_l1.x, cr_l1.y); ctx.lineTo(cr_r1.x, cr_r1.y)
                ctx.lineTo(cr_r2.x, cr_r2.y); ctx.lineTo(cr_l2.x, cr_l2.y)
                ctx.closePath(); ctx.fill()

                var buildings = [

                    { x1: -110, x2: -70, z1: 20, z2: 68, h: 22 },
                    { x1: -110, x2: -70, z1: 82, z2: 126, h: 32 },
                    { x1: -110, x2: -70, z1: 172, z2: 218, h: 26 },
                    { x1: -110, x2: -70, z1: 230, z2: 275, h: 30 },

                    { x1: -20, x2: 20, z1: 20, z2: 68, h: 28 },
                    { x1: -20, x2: 20, z1: 82, z2: 126, h: 42 },
                    { x1: -20, x2: 20, z1: 172, z2: 218, h: 28 },
                    { x1: -20, x2: 20, z1: 230, z2: 275, h: 36 },

                    { x1: 70, x2: 110, z1: 20, z2: 68, h: 22 },
                    { x1: 70, x2: 110, z1: 82, z2: 126, h: 38 },
                    { x1: 70, x2: 110, z1: 172, z2: 218, h: 24 },
                    { x1: 70, x2: 110, z1: 230, z2: 275, h: 32 }
                ]

                for (var b = 0; b < buildings.length; b++) {
                    var blk = buildings[b]
                    var bg1 = project(blk.x1, blk.z1, 0), bg2 = project(blk.x2, blk.z1, 0)
                    var bg3 = project(blk.x2, blk.z2, 0), bg4 = project(blk.x1, blk.z2, 0)
                    var br1 = project(blk.x1, blk.z1, blk.h), br2 = project(blk.x2, blk.z1, blk.h)
                    var br3 = project(blk.x2, blk.z2, blk.h), br4 = project(blk.x1, blk.z2, blk.h)

                    ctx.fillStyle = "#0c1524"
                    ctx.beginPath()
                    ctx.moveTo(bg1.x, bg1.y); ctx.lineTo(bg2.x, bg2.y)
                    ctx.lineTo(br2.x, br2.y); ctx.lineTo(br1.x, br1.y)
                    ctx.closePath(); ctx.fill()

                    ctx.fillStyle = blk.x1 < 0 ? "#132034" : "#0f1a2a"
                    ctx.beginPath()
                    if (blk.x1 < 0) {
                        ctx.moveTo(bg2.x, bg2.y); ctx.lineTo(bg3.x, bg3.y)
                        ctx.lineTo(br3.x, br3.y); ctx.lineTo(br2.x, br2.y)
                    } else {
                        ctx.moveTo(bg4.x, bg4.y); ctx.lineTo(bg1.x, bg1.y)
                        ctx.lineTo(br1.x, br1.y); ctx.lineTo(br4.x, br4.y)
                    }
                    ctx.closePath(); ctx.fill()

                    ctx.fillStyle = "#182840"
                    ctx.beginPath()
                    ctx.moveTo(br1.x, br1.y); ctx.lineTo(br2.x, br2.y)
                    ctx.lineTo(br3.x, br3.y); ctx.lineTo(br4.x, br4.y)
                    ctx.closePath(); ctx.fill()

                    ctx.strokeStyle = Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.25)
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(br1.x, br1.y); ctx.lineTo(br2.x, br2.y)
                    ctx.lineTo(br3.x, br3.y); ctx.lineTo(br4.x, br4.y)
                    ctx.closePath(); ctx.stroke()
                }

                ctx.strokeStyle = "rgba(255, 255, 255, 0.2)"
                ctx.lineWidth = 2
                for (var rz = 5; rz < 285; rz += 30) {
                    var dashZ = (rz + root.roadScroll) % 285
                    if (dashZ > 5 && dashZ < 280) {

                        var d1_s = project(-45, dashZ, 0)
                        var d1_e = project(-45, dashZ + 12, 0)
                        ctx.beginPath(); ctx.moveTo(d1_s.x, d1_s.y); ctx.lineTo(d1_e.x, d1_e.y); ctx.stroke()

                        var d2_s = project(45, dashZ, 0)
                        var d2_e = project(45, dashZ + 12, 0)
                        ctx.beginPath(); ctx.moveTo(d2_s.x, d2_s.y); ctx.lineTo(d2_e.x, d2_e.y); ctx.stroke()
                    }
                }

                var routePts = [
                    project(-45, 30, 0),
                    project(-45, 147, 0),
                    project(45, 147, 0),
                    project(45, 255, 0)
                ]

                ctx.strokeStyle = Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.35)
                ctx.lineWidth = 9 * root.camZoom
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.beginPath()
                ctx.moveTo(routePts[0].x, routePts[0].y)
                for (var r = 1; r < routePts.length; r++) ctx.lineTo(routePts[r].x, routePts[r].y)
                ctx.stroke()

                ctx.strokeStyle = root.accent
                ctx.lineWidth = 3.5 * root.camZoom
                ctx.beginPath()
                ctx.moveTo(routePts[0].x, routePts[0].y)
                for (var r2 = 1; r2 < routePts.length; r2++) ctx.lineTo(routePts[r2].x, routePts[r2].y)
                ctx.stroke()

                var pStart = routePts[0]
                ctx.strokeStyle = root.primary
                ctx.lineWidth = 2.5
                ctx.beginPath()
                ctx.arc(pStart.x, pStart.y, 7 * pStart.scale, 0, Math.PI * 2)
                ctx.stroke()
                ctx.fillStyle = root.cardBg
                ctx.fill()

                var pDest = routePts[3]
                var pDestTop = project(45, 255, 36)

                ctx.strokeStyle = "rgba(255, 23, 68, 0.6)"
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.arc(pDest.x, pDest.y, 10 * pDest.scale, 0, Math.PI * 2)
                ctx.stroke()

                var beamDestGrad = ctx.createLinearGradient(0, pDest.y, 0, pDestTop.y)
                beamDestGrad.addColorStop(0.0, "rgba(255, 23, 68, 0.85)")
                beamDestGrad.addColorStop(1.0, "rgba(255, 60, 100, 0.2)")
                ctx.strokeStyle = beamDestGrad
                ctx.lineWidth = 2.5
                ctx.beginPath()
                ctx.moveTo(pDest.x, pDest.y)
                ctx.lineTo(pDestTop.x, pDestTop.y)
                ctx.stroke()

                ctx.fillStyle = "#ff1744"
                ctx.beginPath()
                ctx.arc(pDestTop.x, pDestTop.y, 6.5, 0, Math.PI * 2)
                ctx.fill()
                ctx.fillStyle = "#ffffff"
                ctx.beginPath()
                ctx.arc(pDestTop.x, pDestTop.y, 2.5, 0, Math.PI * 2)
                ctx.fill()

                var carProj = project(root.carWorldX, root.carWorldZ, 0)
                var carScale = carProj.scale

                ctx.save()
                ctx.translate(carProj.x, carProj.y)
                ctx.rotate(root.carHeading * Math.PI / 180.0)

                var headGrad = ctx.createLinearGradient(0, -6 * carScale, 0, -42 * carScale)
                headGrad.addColorStop(0.0, "rgba(" + Math.round(root.accent.r * 255) + "," + Math.round(root.accent.g * 255) + "," + Math.round(root.accent.b * 255) + ", 0.55)")
                headGrad.addColorStop(1.0, "rgba(" + Math.round(root.accent.r * 255) + "," + Math.round(root.accent.g * 255) + "," + Math.round(root.accent.b * 255) + ", 0.0)")
                ctx.fillStyle = headGrad
                ctx.beginPath()
                ctx.moveTo(-5 * carScale, -8 * carScale)
                ctx.lineTo(-14 * carScale, -42 * carScale)
                ctx.lineTo(14 * carScale, -42 * carScale)
                ctx.lineTo(5 * carScale, -8 * carScale)
                ctx.closePath()
                ctx.fill()

                var cw = 15 * carScale
                var cl = 26 * carScale
                var halfW = cw / 2
                var halfL = cl / 2

                ctx.fillStyle = "#e2f9fc"
                ctx.strokeStyle = root.primary
                ctx.lineWidth = 1.5
                ctx.beginPath()
                ctx.rect(-halfW, -halfL, cw, cl)
                ctx.fill()
                ctx.stroke()

                ctx.fillStyle = "#0c1826"
                ctx.fillRect(-halfW + 2 * carScale, -halfL + 4 * carScale, cw - 4 * carScale, 5 * carScale)

                ctx.fillRect(-halfW + 3 * carScale, halfL - 7 * carScale, cw - 6 * carScale, 3.5 * carScale)

                ctx.fillStyle = root.accent
                ctx.fillRect(-halfW + 1 * carScale, -halfL, 3 * carScale, 2 * carScale)
                ctx.fillRect(halfW - 4 * carScale, -halfL, 3 * carScale, 2 * carScale)

                ctx.fillStyle = "#ff1744"
                ctx.fillRect(-halfW + 1 * carScale, halfL - 2 * carScale, 3 * carScale, 2 * carScale)
                ctx.fillRect(halfW - 4 * carScale, halfL - 2 * carScale, 3 * carScale, 2 * carScale)

                ctx.restore()
            }
        }

        SequentialAnimation {
            id: car3dNavAnimation
            running: true
            loops: Animation.Infinite

            ScriptAction {
                script: {
                    root.carWorldX = -45
                    root.carWorldZ = 30
                    root.carHeading = 0
                    root.camZoom = 1.0
                    root.camPitchBias = 0.0
                }
            }
            ParallelAnimation {

                NumberAnimation {
                    target: root
                    property: "carWorldZ"
                    from: 30
                    to: 147
                    duration: 3600
                    easing.type: Easing.InOutQuad
                }

                SequentialAnimation {
                    NumberAnimation {
                        target: root
                        property: "camPitchBias"
                        from: 0.0
                        to: 0.36
                        duration: 2000
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: root
                        property: "camPitchBias"
                        from: 0.36
                        to: 0.06
                        duration: 1600
                        easing.type: Easing.InOutQuad
                    }
                }

                SequentialAnimation {
                    NumberAnimation {
                        target: root
                        property: "camZoom"
                        from: 1.0
                        to: 1.48
                        duration: 2000
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: root
                        property: "camZoom"
                        from: 1.48
                        to: 1.06
                        duration: 1600
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            NumberAnimation {
                target: root
                property: "carHeading"
                from: 0
                to: 90
                duration: 380
                easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                target: root
                property: "carWorldX"
                from: -45
                to: 45
                duration: 2200
                easing.type: Easing.Linear
            }

            NumberAnimation {
                target: root
                property: "carHeading"
                from: 90
                to: 0
                duration: 380
                easing.type: Easing.InOutQuad
            }

            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "carWorldZ"
                    from: 147
                    to: 255
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }
                SequentialAnimation {
                    NumberAnimation {
                        target: root
                        property: "camPitchBias"
                        from: 0.06
                        to: 0.32
                        duration: 1600
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: root
                        property: "camPitchBias"
                        from: 0.32
                        to: 0.12
                        duration: 1400
                        easing.type: Easing.InOutQuad
                    }
                }
                SequentialAnimation {
                    NumberAnimation {
                        target: root
                        property: "camZoom"
                        from: 1.06
                        to: 1.42
                        duration: 1600
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: root
                        property: "camZoom"
                        from: 1.42
                        to: 1.10
                        duration: 1400
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            PauseAnimation { duration: 1500 }
        }

        Timer {
            interval: 50
            running: true
            repeat: true
            onTriggered: {
                root.roadScroll = (root.roadScroll + 2.5) % 30.0
            }
        }

        Rectangle {
            id: trafficSignCard
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 56
            width: 50
            height: 60
            radius: 8
            color: root.cardBg
            border.color: root.cardBorder
            border.width: 1
            z: 25

            property int signIndex: 0

            Column {
                anchors.centerIn: parent
                spacing: 3

                Canvas {
                    id: signCanvas
                    width: 34
                    height: 34
                    anchors.horizontalCenter: parent.horizontalCenter
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var cx = 17, cy = 17, r = 15

                        if (trafficSignCard.signIndex === 0 || trafficSignCard.signIndex === 3) {

                            ctx.fillStyle = "#ffffff"
                            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill()
                            ctx.strokeStyle = "#e53935"
                            ctx.lineWidth = 3.5
                            ctx.stroke()

                            ctx.fillStyle = "#111111"
                            ctx.font = "bold 12px 'Courier New'"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText(trafficSignCard.signIndex === 0 ? "50" : "60", cx, cy + 1)
                        }
                        else if (trafficSignCard.signIndex === 1) {

                            ctx.fillStyle = "#fdd835"
                            ctx.strokeStyle = "#d32f2f"
                            ctx.lineWidth = 2.5
                            ctx.beginPath()
                            ctx.moveTo(17, 3)
                            ctx.lineTo(31, 30)
                            ctx.lineTo(3, 30)
                            ctx.closePath()
                            ctx.fill()
                            ctx.stroke()

                            ctx.fillStyle = "#212121"
                            ctx.font = "bold 13px 'Courier New'"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText("!", cx, cy + 5)
                        }
                        else if (trafficSignCard.signIndex === 2) {

                            ctx.fillStyle = "#d32f2f"
                            ctx.beginPath()
                            var sides = 8
                            for (var i = 0; i < sides; i++) {
                                var a = i * Math.PI / 4 + Math.PI / 8
                                var sx = cx + Math.cos(a) * r
                                var sy = cy + Math.sin(a) * r
                                if (i === 0) ctx.moveTo(sx, sy)
                                else ctx.lineTo(sx, sy)
                            }
                            ctx.closePath()
                            ctx.fill()
                            ctx.strokeStyle = "#ffffff"
                            ctx.lineWidth = 1.5
                            ctx.stroke()

                            ctx.fillStyle = "#ffffff"
                            ctx.font = "bold 8.5px 'Courier New'"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText("STOP", cx, cy)
                        }
                        else {

                            ctx.fillStyle = "#1976d2"
                            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill()
                            ctx.strokeStyle = "#ffffff"
                            ctx.lineWidth = 1.5
                            ctx.stroke()

                            ctx.strokeStyle = "#ffffff"
                            ctx.fillStyle = "#ffffff"
                            ctx.lineWidth = 2.5
                            ctx.beginPath()
                            ctx.moveTo(17, 24); ctx.lineTo(17, 11); ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(17, 7); ctx.lineTo(12, 13); ctx.lineTo(22, 13); ctx.closePath(); ctx.fill()
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        switch (trafficSignCard.signIndex) {
                            case 0: return "LIMIT 50"
                            case 1: return "CAUTION"
                            case 2: return "STOP"
                            case 3: return "LIMIT 60"
                            case 4: return "AHEAD"
                            default: return "SIGN"
                        }
                    }
                    color: Qt.rgba(1, 1, 1, 0.75)
                    font.pixelSize: 7
                    font.bold: true
                    font.family: "Courier New"
                }
            }

            scale: 1.0
            Behavior on scale {
                SequentialAnimation {
                    NumberAnimation { to: 0.1; duration: 150; easing.type: Easing.InQuad }
                    NumberAnimation { to: 1.0; duration: 250; easing.type: Easing.OutBack }
                }
            }

            Timer {
                interval: 7000
                running: true
                repeat: true
                onTriggered: {
                    trafficSignCard.scale = 0.1
                    signSwitchTimer.restart()
                }
            }

            Timer {
                id: signSwitchTimer
                interval: 160
                repeat: false
                onTriggered: {
                    trafficSignCard.signIndex = (trafficSignCard.signIndex + 1) % 5
                    signCanvas.requestPaint()
                    trafficSignCard.scale = 1.0
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 24
            height: 28
            radius: 14
            color: root.cardBg
            border.color: root.cardBorder
            border.width: 1
            z: 20

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "ETA 2 min"
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Courier New"
                }

                Text {
                    text: "•"
                    color: Qt.rgba(1, 1, 1, 0.3)
                    font.pixelSize: 11
                }

                Text {
                    text: "SIMULATED"
                    color: root.primary
                    font.pixelSize: 9
                    font.bold: true
                    font.family: "Courier New"
                    font.letterSpacing: 1
                }
            }
        }
    }
}

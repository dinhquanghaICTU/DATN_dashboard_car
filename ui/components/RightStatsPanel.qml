import QtQuick 2.15

Item {
    id: root
    width: 224
    height: 416

    property int themeIndex: 0
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color dangerColor: "#ff4444"
    property color warningColor: "#ffcc00"
    property real displaySpeedKmh: 45.0
    property real tripDistanceKm: 1.5

    // ================= MAIN CONTAINER =================
    Rectangle {
        anchors.fill: parent
        radius: 18
        color: "#090e18"
        border.color: Qt.rgba(0, 229, 204, 0.25)
        border.width: 1.5
        clip: true

        // 1. TOP HEADER STATS ROW
        Row {
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            spacing: 8
            z: 20

            // Speed Badge (Left)
            Rectangle {
                width: Math.floor((parent.width - 8) * 0.55)
                height: 38
                radius: 8
                color: "#111928"
                border.color: Qt.rgba(0, 229, 204, 0.3)
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "↗"
                        color: "#00e5cc"
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
                                color: "#00e5cc"
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "Courier New"
                            }
                            Text {
                                text: "km/h"
                                color: Qt.rgba(0, 229, 204, 0.8)
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

            // Distance Badge (Right)
            Rectangle {
                width: Math.floor((parent.width - 8) * 0.45)
                height: 38
                radius: 8
                color: "#111928"
                border.color: Qt.rgba(255, 255, 255, 0.1)
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

        // 2. STYLIZED CITY GRID & ROUTE MAP (CANVAS)
        Canvas {
            id: mapCanvas
            anchors.fill: parent
            z: 5
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                // A. Draw Dark City Blocks
                ctx.fillStyle = "#0c1322"
                var blockW = 32, blockH = 26, gap = 12
                var startX = 14, startY = 56

                for (var r = 0; r < 12; r++) {
                    for (var c = 0; c < 5; c++) {
                        var bx = startX + c * (blockW + gap)
                        var by = startY + r * (blockH + gap)
                        ctx.fillRect(bx, by, blockW, blockH)
                    }
                }

                // B. Draw Main Road Avenues (Dark Blue-Grey)
                ctx.strokeStyle = "#162236"
                ctx.lineWidth = 14
                ctx.beginPath()
                // Vertical Avenue 1 (Left road)
                ctx.moveTo(66, 50); ctx.lineTo(66, 380); ctx.stroke()
                // Vertical Avenue 2 (Right road)
                ctx.moveTo(165, 50); ctx.lineTo(165, 380); ctx.stroke()
                // Horizontal Cross Streets
                ctx.moveTo(10, 195); ctx.lineTo(226, 195); ctx.stroke()
                ctx.moveTo(10, 310); ctx.lineTo(226, 310); ctx.stroke()
                ctx.moveTo(10, 85); ctx.lineTo(226, 85); ctx.stroke()

                // C. Draw Glowing Neon Cyan Route Line
                // Route: (66, 320) -> Up to (66, 195) -> Right to (165, 195) -> Up to (165, 75)
                ctx.strokeStyle = "rgba(0, 229, 204, 0.35)"
                ctx.lineWidth = 8
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.shadowColor = "#00e5cc"
                ctx.shadowBlur = 12

                ctx.beginPath()
                ctx.moveTo(66, 320)
                ctx.lineTo(66, 195)
                ctx.lineTo(165, 195)
                ctx.lineTo(165, 75)
                ctx.stroke()

                // Core Route Line (Bright White-Cyan)
                ctx.strokeStyle = "#00ffff"
                ctx.lineWidth = 3.5
                ctx.shadowBlur = 0
                ctx.beginPath()
                ctx.moveTo(66, 320)
                ctx.lineTo(66, 195)
                ctx.lineTo(165, 195)
                ctx.lineTo(165, 75)
                ctx.stroke()

                // Start Marker (Glowing Cyan Ring)
                ctx.strokeStyle = "#00e5cc"
                ctx.lineWidth = 3
                ctx.beginPath()
                ctx.arc(66, 320, 7, 0, Math.PI * 2)
                ctx.stroke()
                ctx.fillStyle = "#090e18"
                ctx.fill()

                // End Marker (Red Destination Pin)
                ctx.fillStyle = "#ff1744"
                ctx.shadowColor = "#ff1744"
                ctx.shadowBlur = 10
                ctx.beginPath()
                ctx.arc(165, 75, 7, 0, Math.PI * 2)
                ctx.fill()
                ctx.shadowBlur = 0

                ctx.fillStyle = "#ffffff"
                ctx.beginPath()
                ctx.arc(165, 75, 2.5, 0, Math.PI * 2)
                ctx.fill()
            }
        }

        // ================= 3. ANIMATED MOVING CAR ("xe di chuyển động") =================
        Item {
            id: movingCar
            width: 18
            height: 28
            z: 15
            x: 66 - width / 2
            y: 320 - height / 2
            rotation: 0

            // Sleek Car Body
            Rectangle {
                anchors.fill: parent
                radius: 6
                color: "#e2f9fc"
                border.color: "#00e5cc"
                border.width: 1.5

                // Front Windshield
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 12
                    height: 5
                    radius: 2
                    color: "#0a1826"
                }

                // Rear Window
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 10
                    height: 3
                    radius: 1
                    color: "#0a1826"
                }

                // Front Headlights (Glowing Cyan/White)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 1
                    width: 3; height: 2; radius: 1; color: "#00ffff"
                }
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 1
                    width: 3; height: 2; radius: 1; color: "#00ffff"
                }

                // Rear Taillights (Red)
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.margins: 1
                    width: 3; height: 2; radius: 1; color: "#ff1744"
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 1
                    width: 3; height: 2; radius: 1; color: "#ff1744"
                }
            }

            // Headlight Beams (Glowing Cones forward)
            Canvas {
                anchors.bottom: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: 24
                height: 14
                opacity: 0.6
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var grad = ctx.createLinearGradient(0, height, 0, 0)
                    grad.addColorStop(0.0, "rgba(0, 255, 255, 0.5)")
                    grad.addColorStop(1.0, "rgba(0, 255, 255, 0.0)")
                    ctx.fillStyle = grad
                    ctx.beginPath()
                    ctx.moveTo(6, height); ctx.lineTo(1, 0); ctx.lineTo(9, 0); ctx.lineTo(8, height); ctx.fill()
                    ctx.beginPath()
                    ctx.moveTo(16, height); ctx.lineTo(15, 0); ctx.lineTo(23, 0); ctx.lineTo(18, height); ctx.fill()
                }
            }
        }

        // Continuous Route Movement Animation for the Car
        SequentialAnimation {
            id: carNavAnimation
            running: true
            loops: Animation.Infinite

            // Step 1: Start at (66, 320), move straight UP to Corner 1 (66, 195)
            ScriptAction {
                script: {
                    movingCar.x = 66 - movingCar.width / 2
                    movingCar.y = 320 - movingCar.height / 2
                    movingCar.rotation = 0
                }
            }
            NumberAnimation {
                target: movingCar
                property: "y"
                from: 320 - movingCar.height / 2
                to: 195 - movingCar.height / 2
                duration: 3200
                easing.type: Easing.Linear
            }

            // Step 2: Rotate 90 degrees to face RIGHT
            RotationAnimation {
                target: movingCar
                property: "rotation"
                from: 0
                to: 90
                duration: 350
                direction: RotationAnimation.Clockwise
            }

            // Step 3: Move RIGHT along Avenue to Corner 2 (165, 195)
            NumberAnimation {
                target: movingCar
                property: "x"
                from: 66 - movingCar.width / 2
                to: 165 - movingCar.width / 2
                duration: 2600
                easing.type: Easing.Linear
            }

            // Step 4: Rotate 90 degrees back to face UP
            RotationAnimation {
                target: movingCar
                property: "rotation"
                from: 90
                to: 0
                duration: 350
                direction: RotationAnimation.Counterclockwise
            }

            // Step 5: Move UP to Destination Pin (165, 85)
            NumberAnimation {
                target: movingCar
                property: "y"
                from: 195 - movingCar.height / 2
                to: 85 - movingCar.height / 2
                duration: 2800
                easing.type: Easing.Linear
            }

            // Pause at destination for 1 second, then loop
            PauseAnimation { duration: 1200 }
        }

        // ================= 4. DYNAMIC TRAFFIC SIGN HUD ("đổi cả biển báo giao thông") =================
        Rectangle {
            id: trafficSignCard
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.top: parent.top
            anchors.topMargin: 56
            width: 52
            height: 64
            radius: 8
            color: "#101928"
            border.color: Qt.rgba(0, 229, 204, 0.4)
            border.width: 1
            z: 25

            property int signIndex: 0
            // Danh sách các biển báo giao thông thực tế:
            // 0: Giới hạn tốc độ 50 km/h (Speed Limit 50)
            // 1: Cảnh báo đường trơn / nguy hiểm (Slippery / Caution)
            // 2: Dừng lại (STOP)
            // 3: Giới hạn tốc độ 60 km/h (Speed Limit 60)
            // 4: Hướng đi thẳng phải theo (Straight Only)

            Column {
                anchors.centerIn: parent
                spacing: 4

                // Vector Traffic Sign Icon (Canvas)
                Canvas {
                    id: signCanvas
                    width: 36
                    height: 36
                    anchors.horizontalCenter: parent.horizontalCenter
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var cx = 18, cy = 18, r = 16

                        if (trafficSignCard.signIndex === 0 || trafficSignCard.signIndex === 3) {
                            // Biển Tròn Giới hạn tốc độ (50 hoặc 60 km/h)
                            ctx.fillStyle = "#ffffff"
                            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill()
                            ctx.strokeStyle = "#e53935"
                            ctx.lineWidth = 4
                            ctx.stroke()

                            ctx.fillStyle = "#111111"
                            ctx.font = "bold 13px 'Courier New'"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText(trafficSignCard.signIndex === 0 ? "50" : "60", cx, cy + 1)
                        }
                        else if (trafficSignCard.signIndex === 1) {
                            // Biển Tam giác Cảnh báo nguy hiểm / Trơn trượt (⚠️)
                            ctx.fillStyle = "#fdd835"
                            ctx.strokeStyle = "#d32f2f"
                            ctx.lineWidth = 3
                            ctx.beginPath()
                            ctx.moveTo(18, 3)
                            ctx.lineTo(34, 32)
                            ctx.lineTo(2, 32)
                            ctx.closePath()
                            ctx.fill()
                            ctx.stroke()

                            ctx.fillStyle = "#212121"
                            ctx.font = "bold 14px 'Courier New'"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText("!", cx, cy + 5)
                        }
                        else if (trafficSignCard.signIndex === 2) {
                            // Biển Bát giác STOP
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
                            ctx.font = "bold 9px 'Courier New'"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText("STOP", cx, cy)
                        }
                        else {
                            // Biển Hướng đi thẳng (Tròn Xanh mũi tên trắng)
                            ctx.fillStyle = "#1976d2"
                            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill()
                            ctx.strokeStyle = "#ffffff"
                            ctx.lineWidth = 1.5
                            ctx.stroke()

                            ctx.strokeStyle = "#ffffff"
                            ctx.fillStyle = "#ffffff"
                            ctx.lineWidth = 3
                            ctx.beginPath()
                            ctx.moveTo(18, 26); ctx.lineTo(18, 12); ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(18, 8); ctx.lineTo(13, 14); ctx.lineTo(23, 14); ctx.closePath(); ctx.fill()
                        }
                    }
                }

                // Mini Traffic Sign Label
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
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font.pixelSize: 7
                    font.bold: true
                    font.family: "Courier New"
                }
            }

            // Smooth scale/pop animation on sign change
            scale: 1.0
            Behavior on scale {
                SequentialAnimation {
                    NumberAnimation { to: 0.1; duration: 150; easing.type: Easing.InQuad }
                    NumberAnimation { to: 1.0; duration: 250; easing.type: Easing.OutBack }
                }
            }

            // Timer: Tự động đổi biển báo giao thông sau mỗi 7 giây!
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

        // ================= 5. BOTTOM ETA BADGE =================
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 24
            height: 28
            radius: 14
            color: "#0f1624"
            border.color: Qt.rgba(0, 229, 204, 0.2)
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
                    color: "#00e5cc"
                    font.pixelSize: 9
                    font.bold: true
                    font.family: "Courier New"
                    font.letterSpacing: 1
                }
            }
        }
    }
}

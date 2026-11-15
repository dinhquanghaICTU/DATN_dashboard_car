import QtQuick 2.15

Item {
    id: root
    width: 300
    height: 416

    property bool introActive: false
    property int themeIndex: 0
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color cardBg: "#0a101d"
    property color cardBorder: Qt.rgba(0, 229, 204, 0.25)
    property color warningColor: "#ffcc00"
    property color dangerColor: "#ff4444"
    property color bgColor: "#080c12"
    property color rpmColor: "#9966ff"
    property real displaySpeed: 0
    property real displaySpeedKmh: 0
    property real displayRpm: 0

    property bool leftSignal: false
    property bool rightSignal: false
    property bool hazardActive: false
    property bool headLight: false
    property int signalTick: 0

    signal toggleLeftSignal()
    signal toggleRightSignal()
    signal toggleHazard()
    signal toggleHeadLight()

    onThemeIndexChanged: repaint()
    onPrimaryChanged: repaint()
    onAccentChanged: repaint()
    onWarningColorChanged: repaint()
    onDangerColorChanged: repaint()
    onDisplaySpeedKmhChanged: speedGaugeCanvas.requestPaint()

    function repaint() {
        speedGaugeStaticCanvas.requestPaint()
        speedGaugeCanvas.requestPaint()
    }

    Column {
        anchors.fill: parent
        spacing: 8

        Item {
            width: parent.width
            height: 310

            Canvas {
                id: leftArrow
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.top: parent.top
                anchors.topMargin: 12
                width: 32
                height: 24
                property bool active: (root.leftSignal || root.hazardActive) && (root.signalTick === 0)
                onActiveChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = active ? "#00e676" : "rgba(255,255,255,0.12)"
                    ctx.beginPath()
                    ctx.moveTo(8, 12)
                    ctx.lineTo(20, 2)
                    ctx.lineTo(20, 7)
                    ctx.lineTo(30, 7)
                    ctx.lineTo(30, 17)
                    ctx.lineTo(20, 17)
                    ctx.lineTo(20, 22)
                    ctx.closePath()
                    ctx.fill()
                }
            }

            Column {
                anchors.top: parent.top
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2
                Text {
                    text: "60"
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Courier New"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Rectangle {
                    width: 2
                    height: 8
                    color: Qt.rgba(1, 1, 1, 0.5)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Canvas {
                id: rightArrow
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.top: parent.top
                anchors.topMargin: 12
                width: 32
                height: 24
                property bool active: (root.rightSignal || root.hazardActive) && (root.signalTick === 0)
                onActiveChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = active ? "#00e676" : "rgba(255,255,255,0.12)"
                    ctx.beginPath()
                    ctx.moveTo(24, 12)
                    ctx.lineTo(12, 2)
                    ctx.lineTo(12, 7)
                    ctx.lineTo(2, 7)
                    ctx.lineTo(2, 17)
                    ctx.lineTo(12, 17)
                    ctx.lineTo(12, 22)
                    ctx.closePath()
                    ctx.fill()
                }
            }

            Canvas {
                id: speedGaugeStaticCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var cx = width / 2
                    var cy = 135
                    var r = 95
                    var startAngle = Math.PI * 0.75
                    var endAngle = Math.PI * 2.25

                    ctx.beginPath()
                    ctx.arc(cx, cy, r, startAngle, endAngle)
                    ctx.strokeStyle = "rgba(255,255,255,0.08)"
                    ctx.lineWidth = 14
                    ctx.lineCap = "round"
                    ctx.stroke()

                    var redStart = startAngle + (100.0 / 120.0) * (endAngle - startAngle)
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, redStart, endAngle)
                    ctx.strokeStyle = "rgba(255, 50, 70, 0.45)"
                    ctx.lineWidth = 14
                    ctx.lineCap = "round"
                    ctx.stroke()

                    var ticks = [
                        { val: 0, text: "0" },
                        { val: 20, text: "20" },
                        { val: 40, text: "40" },
                        { val: 60, text: "" },
                        { val: 80, text: "80" },
                        { val: 100, text: "100" },
                        { val: 120, text: "120" }
                    ]

                    for (var i = 0; i <= 24; i++) {
                        var angle = startAngle + (i / 24.0) * (endAngle - startAngle)
                        var isMajor = (i % 4 === 0)
                        var tickR1 = r + 10
                        var tickR2 = isMajor ? r + 18 : r + 14
                        ctx.beginPath()
                        ctx.moveTo(cx + Math.cos(angle) * tickR1, cy + Math.sin(angle) * tickR1)
                        ctx.lineTo(cx + Math.cos(angle) * tickR2, cy + Math.sin(angle) * tickR2)
                        ctx.strokeStyle = i >= 20 ? "#ff3344" : (isMajor ? "rgba(255,255,255,0.7)" : "rgba(255,255,255,0.2)")
                        ctx.lineWidth = isMajor ? 2.0 : 1.0
                        ctx.stroke()
                    }

                    ctx.font = "bold 11px 'Courier New'"
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    for (var j = 0; j < ticks.length; j++) {
                        if (ticks[j].text === "") continue
                        var numAngle = startAngle + (ticks[j].val / 120.0) * (endAngle - startAngle)
                        var textR = r + 28
                        var tx = cx + Math.cos(numAngle) * textR
                        var ty = cy + Math.sin(numAngle) * textR
                        ctx.fillStyle = ticks[j].val >= 100 ? "#ff3344" : "rgba(255,255,255,0.75)"
                        ctx.fillText(ticks[j].text, tx, ty)
                    }
                }
            }

            Canvas {
                id: speedGaugeCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var cx = width / 2
                    var cy = 135
                    var r = 95
                    var startAngle = Math.PI * 0.75
                    var totalAngle = Math.PI * 1.50
                    var pct = Math.min(Math.max(root.displaySpeedKmh / 120.0, 0.0), 1.0)
                    if (pct <= 0.001) return

                    var endAngle = startAngle + pct * totalAngle

                    var grad = ctx.createLinearGradient(0, 0, width, height)
                    grad.addColorStop(0.0, root.primary)
                    grad.addColorStop(0.8, root.accent)
                    grad.addColorStop(1.0, root.displaySpeedKmh >= 100 ? root.dangerColor : root.primary)

                    ctx.beginPath()
                    ctx.arc(cx, cy, r, startAngle, endAngle)
                    ctx.strokeStyle = grad
                    ctx.lineWidth = 14
                    ctx.lineCap = "round"
                    ctx.stroke()

                    var tipX = cx + Math.cos(endAngle) * r
                    var tipY = cy + Math.sin(endAngle) * r
                    ctx.beginPath()
                    ctx.arc(tipX, tipY, 7, 0, Math.PI * 2)
                    ctx.fillStyle = "#ffffff"
                    ctx.fill()
                    ctx.lineWidth = 2
                    ctx.strokeStyle = root.primary
                    ctx.stroke()
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 84
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.displaySpeedKmh.toFixed(1)
                    color: "#ffffff"
                    font.pixelSize: 42
                    font.bold: true
                    font.family: "Courier New"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "KM/H"
                    color: root.primary
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Courier New"
                    font.letterSpacing: 3
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 160
                width: 120
                height: 26
                radius: 13
                color: "#261947"
                border.color: "#6536c9"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.displayRpm.toFixed(0) + " RPM"
                    color: "#e2d9fc"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "Courier New"
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 194
                text: root.displaySpeed.toFixed(3) + " m/s"
                color: Qt.rgba(1, 1, 1, 0.45)
                font.pixelSize: 11
                font.family: "Courier New"
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 228
                width: 200
                height: 26
                radius: 13
                color: root.cardBg
                border.color: Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.35)
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: root.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "ALL SYSTEMS NORMAL"
                        color: root.primary
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "Courier New"
                        font.letterSpacing: 1
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 94
            radius: 16
            color: root.cardBg
            border.color: root.cardBorder
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Row {
                    spacing: 6
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: root.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "LIGHTS"
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "Courier New"
                        font.letterSpacing: 1
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Rectangle {
                        width: 58; height: 50; radius: 10
                        color: (root.leftSignal && !root.hazardActive && root.signalTick === 0) ? Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.25) : "#131b26"
                        border.color: (root.leftSignal && !root.hazardActive) ? root.primary : Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1.5

                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: "⬅"
                                color: (root.leftSignal && !root.hazardActive && root.signalTick === 0) ? root.primary : "#64748b"
                                font.pixelSize: 18
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: "LEFT"
                                color: (root.leftSignal && !root.hazardActive && root.signalTick === 0) ? root.primary : "#64748b"
                                font.pixelSize: 8
                                font.bold: true
                                font.family: "Courier New"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.toggleLeftSignal()
                        }
                    }

                    Rectangle {
                        width: 58; height: 50; radius: 10
                        color: (root.hazardActive && root.signalTick === 0) ? Qt.rgba(1, 0.1, 0.2, 0.25) : "#131b26"
                        border.color: root.hazardActive ? root.dangerColor : Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1.5

                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: "⚠️"
                                font.pixelSize: 16
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: "HAZARD"
                                color: (root.hazardActive && root.signalTick === 0) ? root.dangerColor : "#64748b"
                                font.pixelSize: 8
                                font.bold: true
                                font.family: "Courier New"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.toggleHazard()
                        }
                    }

                    Rectangle {
                        width: 58; height: 50; radius: 10
                        color: (root.rightSignal && !root.hazardActive && root.signalTick === 0) ? Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.25) : "#131b26"
                        border.color: (root.rightSignal && !root.hazardActive) ? root.primary : Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1.5

                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: "➡"
                                color: (root.rightSignal && !root.hazardActive && root.signalTick === 0) ? root.primary : "#64748b"
                                font.pixelSize: 18
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: "RIGHT"
                                color: (root.rightSignal && !root.hazardActive && root.signalTick === 0) ? root.primary : "#64748b"
                                font.pixelSize: 8
                                font.bold: true
                                font.family: "Courier New"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.toggleRightSignal()
                        }
                    }

                    Rectangle {
                        width: 58; height: 50; radius: 10
                        color: root.headLight ? Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.25) : "#131b26"
                        border.color: root.headLight ? root.primary : Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1.5

                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: "💡"
                                font.pixelSize: 16
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: "LAMP"
                                color: root.headLight ? root.primary : "#64748b"
                                font.pixelSize: 8
                                font.bold: true
                                font.family: "Courier New"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.toggleHeadLight()
                        }
                    }
                }
            }
        }
    }
}

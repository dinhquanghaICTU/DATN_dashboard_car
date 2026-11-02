import QtQuick 2.15

Item {
    id: root
    width: 220
    height: 406

    property int themeIndex: 0
    property string themeName: "AQUA"
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color warningColor: "#ffcc00"
    property color dangerColor: "#ff4444"
    property real batteryLevel: 100.0
    property bool batteryCriticalVisible: true
    property bool leftSignal: false
    property bool rightSignal: false
    property bool headLight: false
    property int signalTick: 0
    property bool temperatureHazardLocked: false

    signal toggleLeftSignal()
    signal toggleRightSignal()
    signal toggleHazard()
    signal toggleHeadLight()
    signal applyTheme(int index)
    signal nextTheme()

    readonly property string fontFamily: "DejaVu Sans"
    readonly property bool hazardOn: leftSignal && rightSignal
    readonly property color batteryColor: batteryLevel > 50 ? accent : batteryLevel > 20 ? warningColor : dangerColor
    readonly property var themeSwatches: ["#00e5cc", "#58d68d", "#ffb347"]

    onThemeIndexChanged: batteryArc.requestPaint()
    onBatteryColorChanged: batteryArc.requestPaint()
    onPrimaryChanged: batteryArc.requestPaint()

    // ---------------------------------------------------------------- Battery
    DashCard {
        id: batteryCard
        y: 0; width: parent.width; height: 192
        title: "BATTERY"
        accentColor: root.batteryColor
        alert: root.batteryLevel < 10.0

        Canvas {
            id: batteryArc
            width: 148; height: 148
            anchors.horizontalCenter: parent.horizontalCenter
            y: 30
            opacity: root.batteryCriticalVisible ? 1.0 : 0.25
            property real batt: root.batteryLevel
            onBattChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var cx = 74, cy = 74, r = 62
                var start = Math.PI * 0.75, sweep = Math.PI * 1.5
                ctx.lineCap = "round"
                ctx.beginPath(); ctx.arc(cx, cy, r, start, start + sweep)
                ctx.strokeStyle = "rgba(255,255,255,0.07)"; ctx.lineWidth = 10; ctx.stroke()
                var pct = Math.max(0, Math.min(root.batteryLevel / 100.0, 1))
                if (pct > 0.005) {
                    var grad = ctx.createLinearGradient(0, height, width, 0)
                    grad.addColorStop(0, root.batteryLevel > 50 ? root.primary : root.batteryColor)
                    grad.addColorStop(1, root.batteryColor)
                    ctx.shadowColor = root.batteryColor; ctx.shadowBlur = 8
                    ctx.beginPath(); ctx.arc(cx, cy, r, start, start + pct * sweep)
                    ctx.strokeStyle = grad; ctx.lineWidth = 10; ctx.stroke()
                    ctx.shadowBlur = 0
                }
            }
        }

        Row {
            anchors.horizontalCenter: batteryArc.horizontalCenter
            y: batteryArc.y + 46
            opacity: root.batteryCriticalVisible ? 1.0 : 0.25
            Text {
                id: battValue
                text: root.batteryLevel.toFixed(0)
                color: "white"
                font.family: root.fontFamily; font.pixelSize: 38; font.bold: true
            }
            Text {
                anchors.baseline: battValue.baseline
                text: "%"
                color: root.batteryColor
                font.family: root.fontFamily; font.pixelSize: 16; font.bold: true
            }
        }
        Text {
            anchors.horizontalCenter: batteryArc.horizontalCenter
            y: batteryArc.y + 96
            text: root.batteryLevel > 50 ? "GOOD" : root.batteryLevel > 20 ? "MEDIUM" : root.batteryLevel >= 10 ? "LOW" : "CRITICAL"
            color: root.batteryColor
            opacity: root.batteryCriticalVisible ? 0.9 : 0.25
            font.family: root.fontFamily; font.pixelSize: 10; font.bold: true; font.letterSpacing: 2
        }
    }

    // ----------------------------------------------------------------- Lights
    DashCard {
        id: lightsCard
        y: batteryCard.y + batteryCard.height + 10
        width: parent.width; height: 122
        title: "LIGHTS"
        accentColor: root.temperatureHazardLocked ? root.dangerColor : root.primary
        alert: root.temperatureHazardLocked

        Text {
            visible: root.temperatureHazardLocked
            anchors.right: parent.right; anchors.rightMargin: 14; y: 12
            text: "LOCKED"
            color: root.dangerColor
            font.family: root.fontFamily; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.4
        }

        Row {
            x: 10; y: 36; spacing: 8
            opacity: root.temperatureHazardLocked ? 0.75 : 1.0

            Repeater {
                // kind: 0 = left, 1 = hazard, 2 = right, 3 = lamp
                model: [
                    { kind: 0, label: "LEFT" },
                    { kind: 1, label: "HAZARD" },
                    { kind: 2, label: "RIGHT" },
                    { kind: 3, label: "LAMP" }
                ]

                Column {
                    id: tile
                    spacing: 6
                    property int kind: modelData.kind
                    property bool active: kind === 0 ? root.leftSignal
                                        : kind === 1 ? root.hazardOn
                                        : kind === 2 ? root.rightSignal
                                        : root.headLight
                    property bool blinking: kind !== 3
                    property bool lit: active && (!blinking || root.signalTick === 0)
                    property color tone: kind === 1 ? root.warningColor : kind === 3 ? root.primary : root.accent

                    Rectangle {
                        width: 44; height: 48; radius: 12
                        color: tile.active ? Qt.rgba(tile.tone.r, tile.tone.g, tile.tone.b, 0.16) : Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: tile.active ? Qt.rgba(tile.tone.r, tile.tone.g, tile.tone.b, 0.65) : Qt.rgba(1, 1, 1, 0.08)
                        scale: tileMouse.pressed ? 0.92 : 1.0
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        Canvas {
                            id: icon
                            width: 24; height: 24
                            anchors.centerIn: parent
                            property bool lit: tile.lit
                            property bool active: tile.active
                            property color tone: tile.tone
                            onLitChanged: requestPaint()
                            onActiveChanged: requestPaint()
                            onToneChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                                var c = lit ? tone : active ? Qt.rgba(tone.r, tone.g, tone.b, 0.35) : "rgba(255,255,255,0.32)"
                                ctx.fillStyle = c; ctx.strokeStyle = c
                                ctx.lineJoin = "round"; ctx.lineCap = "round"
                                if (tile.kind === 0 || tile.kind === 2) {
                                    ctx.save()
                                    if (tile.kind === 2) { ctx.translate(24, 0); ctx.scale(-1, 1) }
                                    ctx.beginPath()
                                    ctx.moveTo(2, 12); ctx.lineTo(11, 3.5); ctx.lineTo(11, 8.5); ctx.lineTo(22, 8.5)
                                    ctx.lineTo(22, 15.5); ctx.lineTo(11, 15.5); ctx.lineTo(11, 20.5); ctx.closePath()
                                    ctx.fill()
                                    ctx.restore()
                                } else if (tile.kind === 1) {
                                    ctx.lineWidth = 2.4
                                    ctx.beginPath(); ctx.moveTo(12, 2.5); ctx.lineTo(22, 20.5); ctx.lineTo(2, 20.5); ctx.closePath(); ctx.stroke()
                                    ctx.lineWidth = 1.8
                                    ctx.beginPath(); ctx.moveTo(12, 9.5); ctx.lineTo(16.5, 17); ctx.lineTo(7.5, 17); ctx.closePath(); ctx.stroke()
                                } else {
                                    ctx.lineWidth = 2.2
                                    ctx.beginPath(); ctx.moveTo(11, 4.5)
                                    ctx.bezierCurveTo(1.5, 4.5, 1.5, 19.5, 11, 19.5)
                                    ctx.closePath(); ctx.stroke()
                                    if (active) { ctx.fill() }
                                    for (var i = 0; i < 4; ++i) {
                                        var yy = 6 + i * 4
                                        ctx.beginPath(); ctx.moveTo(15, yy); ctx.lineTo(22, yy); ctx.stroke()
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            enabled: !root.temperatureHazardLocked
                            onClicked: {
                                if (tile.kind === 0) root.toggleLeftSignal()
                                else if (tile.kind === 1) root.toggleHazard()
                                else if (tile.kind === 2) root.toggleRightSignal()
                                else root.toggleHeadLight()
                            }
                        }
                    }
                    Text {
                        width: 44
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.label
                        color: tile.active ? tile.tone : Qt.rgba(1, 1, 1, 0.4)
                        font.family: root.fontFamily; font.pixelSize: 8; font.bold: true; font.letterSpacing: 0.6
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------ Theme
    DashCard {
        y: lightsCard.y + lightsCard.height + 10
        width: parent.width; height: parent.height - y
        title: "THEME"
        accentColor: root.primary

        Row {
            x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 10
            spacing: 6
            Repeater {
                model: 3
                Item {
                    width: 32; height: 32
                    Rectangle {
                        anchors.centerIn: parent
                        width: root.themeIndex === index ? 30 : 22
                        height: width; radius: width / 2
                        color: "transparent"
                        border.width: 2
                        border.color: root.themeIndex === index ? root.themeSwatches[index] : "transparent"
                        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 20; height: 20; radius: 10
                        color: root.themeSwatches[index]
                        opacity: root.themeIndex === index ? 1.0 : 0.55
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.applyTheme(index)
                    }
                }
            }
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.bottom: parent.bottom; anchors.bottomMargin: 18
            text: root.themeName
            color: root.primary
            font.family: root.fontFamily; font.pixelSize: 13; font.bold: true; font.letterSpacing: 2
            MouseArea {
                anchors.fill: parent
                anchors.margins: -10
                onClicked: root.nextTheme()
            }
        }
    }
}

import QtQuick 2.15

// Turn signal / hazard / headlight controls.
DashCard {
    id: root
    width: 312
    height: 112
    title: "LIGHTS"
    accentColor: temperatureHazardLocked ? dangerColor : (leftSignal || rightSignal || headLight ? accent : primary)
    alert: temperatureHazardLocked

    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color warningColor: "#ffcc00"
    property color dangerColor: "#ff4444"
    property bool leftSignal: false
    property bool rightSignal: false
    property bool headLight: false
    property int signalTick: 0
    property bool temperatureHazardLocked: false

    signal toggleLeftSignal()
    signal toggleRightSignal()
    signal toggleHazard()
    signal toggleHeadLight()

    readonly property string fontFamily: "DejaVu Sans"
    readonly property bool hazardOn: leftSignal && rightSignal

    Text {
        visible: root.temperatureHazardLocked
        anchors.right: parent.right; anchors.rightMargin: 14; y: 12
        text: "LOCKED · OVERHEAT"
        color: root.dangerColor
        font.family: root.fontFamily; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.4
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 34; spacing: 14
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
                spacing: 5
                property int kind: modelData.kind
                property bool active: kind === 0 ? root.leftSignal
                                    : kind === 1 ? root.hazardOn
                                    : kind === 2 ? root.rightSignal
                                    : root.headLight
                property bool blinking: kind !== 3
                property bool lit: active && (!blinking || root.signalTick === 0)
                property color tone: kind === 1 ? root.warningColor : kind === 3 ? root.primary : root.accent

                Rectangle {
                    width: 56; height: 48; radius: 14
                    color: tile.active ? Qt.rgba(tile.tone.r, tile.tone.g, tile.tone.b, 0.16) : Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: tile.active ? Qt.rgba(tile.tone.r, tile.tone.g, tile.tone.b, 0.65) : Qt.rgba(1, 1, 1, 0.08)
                    scale: tileMouse.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Canvas {
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
                    width: 56
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData.label
                    color: tile.active ? tile.tone : Qt.rgba(1, 1, 1, 0.45)
                    font.family: root.fontFamily; font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.8
                }
            }
        }
    }
}

import QtQuick 2.15

Item {
    id: root
    width: 800
    height: 48

    property bool introActive: false
    property color bgColor: "#060a10"
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color weatherPanelColor: "#101827"
    property color weatherIconColor: "#ffd21f"
    property string weatherMode: "sun"
    property bool bleConnected: false

    readonly property string fontFamily: "DejaVu Sans"
    property date now: new Date()

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    // Soft divider under the bar
    Rectangle {
        x: 24; y: parent.height - 1; width: parent.width - 48; height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.5) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Clock
    Row {
        x: 30; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 2
        spacing: 5
        Text {
            id: clockText
            text: Qt.formatTime(root.now, "hh:mm")
            color: "white"
            font.family: root.fontFamily; font.pixelSize: 24; font.bold: true
        }
        Text {
            anchors.baseline: clockText.baseline
            text: Qt.formatTime(root.now, "ss")
            color: root.primary
            font.family: root.fontFamily; font.pixelSize: 12; font.bold: true
        }
    }

    // Date
    Row {
        anchors.centerIn: parent; anchors.verticalCenterOffset: 2
        spacing: 8
        Canvas {
            id: dateIcon
            width: 16; height: 16
            anchors.verticalCenter: parent.verticalCenter
            property color iconColor: root.primary
            onIconColorChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = iconColor; ctx.fillStyle = iconColor; ctx.lineWidth = 1.6
                ctx.strokeRect(2, 3.5, 12, 11)
                ctx.fillRect(2, 3.5, 12, 3)
                ctx.fillRect(4.5, 1, 1.6, 4); ctx.fillRect(10, 1, 1.6, 4)
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(root.now, "ddd, dd MMM yyyy").toUpperCase()
            color: Qt.rgba(1, 1, 1, 0.78)
            font.family: root.fontFamily; font.pixelSize: 13; font.bold: true; font.letterSpacing: 1.5
        }
    }

    // Status chips
    Row {
        anchors.right: parent.right; anchors.rightMargin: 26
        anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 2
        spacing: 8

        Rectangle {
            width: bleRow.width + 22; height: 26; radius: 13
            color: root.bleConnected ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12) : Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: root.bleConnected ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5) : Qt.rgba(1, 1, 1, 0.12)
            Row {
                id: bleRow
                anchors.centerIn: parent; spacing: 6
                Rectangle {
                    width: 7; height: 7; radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.bleConnected ? root.accent : Qt.rgba(1, 1, 1, 0.3)
                }
                Text {
                    text: "BLE"
                    color: root.bleConnected ? root.accent : Qt.rgba(1, 1, 1, 0.45)
                    font.family: root.fontFamily; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.2
                }
            }
        }

        Rectangle {
            width: weatherRow.width + 22; height: 26; radius: 13
            color: root.weatherPanelColor
            border.width: 1
            border.color: Qt.rgba(root.weatherIconColor.r, root.weatherIconColor.g, root.weatherIconColor.b, 0.55)

            Row {
                id: weatherRow
                anchors.centerIn: parent; spacing: 5
                Canvas {
                    id: weatherIcon
                    width: 26; height: 22
                    anchors.verticalCenter: parent.verticalCenter
                    property int weatherAnimTick: 0
                    property string mode: root.weatherMode
                    property color iconColor: root.weatherIconColor
                    onModeChanged: requestPaint()
                    onIconColorChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                        ctx.save()
                        ctx.scale(0.72, 0.72)
                        ctx.lineWidth = 3; ctx.lineCap = "round"; ctx.lineJoin = "round"
                        ctx.fillStyle = iconColor; ctx.strokeStyle = iconColor
                        if (mode === "rain") {
                            ctx.beginPath(); ctx.arc(14, 12, 7, Math.PI, Math.PI * 2); ctx.arc(22, 12, 6, Math.PI, Math.PI * 2); ctx.lineTo(27, 17); ctx.lineTo(7, 17); ctx.closePath(); ctx.fill()
                            for (var r = 0; r < 3; ++r) {
                                var dropY = 21 + ((weatherAnimTick + r * 2) % 6)
                                ctx.beginPath(); ctx.moveTo(11 + r * 7, dropY); ctx.lineTo(9 + r * 7, dropY + 4); ctx.stroke()
                            }
                        } else if (mode === "cloud") {
                            var cloudX = Math.sin(weatherAnimTick * 0.35) * 2
                            ctx.beginPath(); ctx.arc(12 + cloudX, 16, 7, Math.PI, Math.PI * 2); ctx.arc(20 + cloudX, 15, 8, Math.PI, Math.PI * 2); ctx.arc(26 + cloudX, 18, 5, Math.PI, Math.PI * 2); ctx.lineTo(29 + cloudX, 22); ctx.lineTo(6 + cloudX, 22); ctx.closePath(); ctx.fill()
                        } else {
                            ctx.beginPath(); ctx.arc(18, 16, 7, 0, Math.PI * 2); ctx.fill()
                            for (var i = 0; i < 8; ++i) {
                                var a = i * Math.PI / 4 + weatherAnimTick * 0.08
                                ctx.beginPath(); ctx.moveTo(18 + Math.cos(a) * 10.5, 16 + Math.sin(a) * 10.5); ctx.lineTo(18 + Math.cos(a) * 14, 16 + Math.sin(a) * 14); ctx.stroke()
                            }
                        }
                        ctx.restore()
                    }
                    Timer {
                        interval: 120
                        running: !root.introActive
                        repeat: true
                        onTriggered: {
                            weatherIcon.weatherAnimTick = (weatherIcon.weatherAnimTick + 1) % 1000
                            weatherIcon.requestPaint()
                        }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.weatherMode === "rain" ? "RAIN" : root.weatherMode === "cloud" ? "CLOUD" : "SUNNY"
                    color: root.weatherIconColor
                    font.family: root.fontFamily; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.2
                }
            }
        }
    }
}

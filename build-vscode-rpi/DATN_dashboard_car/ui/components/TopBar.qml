import QtQuick 2.15

Item {
    id: root
    width: 800
    height: 43

    property bool introActive: false
    property color bgColor: "#080c12"
    property color primary: "#00e5cc"
    property color topPanelColor: Qt.rgba(0, 0.55, 0.48, 0.35)
    property color weatherPanelColor: "#101827"
    property color weatherIconColor: "#ffd21f"
    property string weatherMode: "sun"

    Rectangle {
        x: 3; y: 3; width: parent.width - 6; height: 40
        color: root.primary; radius: 25
        Rectangle { x: 0; y: 20; width: parent.width; height: 20; color: root.primary }

        Rectangle {
            x: 14; y: 6; width: parent.width - 28; height: 28
            radius: 14
            color: root.topPanelColor
            border.color: Qt.rgba(1, 1, 1, 0.18)
            border.width: 1
        }

        Row {
            x: 30; anchors.verticalCenter: parent.verticalCenter; spacing: 10
            Text {
                text: Qt.formatTime(new Date(), "hh:mm")
                color: root.bgColor; font.pixelSize: 22; font.bold: true; font.family: "Courier New"
                Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm") }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(new Date(), "ss")
                color: Qt.rgba(0, 0, 0, 0.55); font.pixelSize: 11; font.bold: true; font.family: "Courier New"
                Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.text = Qt.formatTime(new Date(), "ss") }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Canvas {
                id: dateIcon
                width: 18; height: 18
                anchors.verticalCenter: parent.verticalCenter
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = root.bgColor; ctx.fillStyle = root.bgColor; ctx.lineWidth = 2
                    ctx.strokeRect(3, 4, 12, 11)
                    ctx.beginPath(); ctx.moveTo(3, 8); ctx.lineTo(15, 8); ctx.stroke()
                    ctx.fillRect(5, 2, 2, 4); ctx.fillRect(11, 2, 2, 4)
                }
                property color iconColor: root.bgColor
                onIconColorChanged: requestPaint()
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(new Date(), "ddd, dd MMM yyyy").toUpperCase()
                color: root.bgColor; font.pixelSize: 15; font.bold: true; font.family: "Courier New"; font.letterSpacing: 1
                Timer { interval: 60000; running: true; repeat: true; onTriggered: parent.text = Qt.formatDate(new Date(), "ddd, dd MMM yyyy").toUpperCase() }
            }
        }

        Rectangle {
            x: parent.width - 166; y: 6; width: 150; height: 28
            radius: 14
            color: root.weatherPanelColor
            border.color: root.weatherIconColor
            border.width: 1

            Row {
                anchors.centerIn: parent; spacing: 8
                Canvas {
                    id: weatherIcon
                    width: 36; height: 32
                    property int weatherAnimTick: 0
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                        ctx.lineWidth = 3; ctx.lineCap = "round"; ctx.lineJoin = "round"
                        ctx.shadowColor = root.weatherIconColor
                        ctx.shadowBlur = 5
                        if (root.weatherMode === "rain") {
                            ctx.fillStyle = root.weatherIconColor
                            ctx.beginPath(); ctx.arc(14, 12, 7, Math.PI, Math.PI * 2); ctx.arc(22, 12, 6, Math.PI, Math.PI * 2); ctx.lineTo(27, 17); ctx.lineTo(7, 17); ctx.closePath(); ctx.fill()
                            ctx.strokeStyle = root.weatherIconColor
                            for (var r = 0; r < 3; ++r) {
                                var dropY = 20 + ((weatherAnimTick + r * 2) % 6)
                                ctx.beginPath(); ctx.moveTo(10 + r * 7, dropY); ctx.lineTo(8 + r * 7, dropY + 4); ctx.stroke()
                            }
                        } else if (root.weatherMode === "cloud") {
                            ctx.fillStyle = root.weatherIconColor
                            var cloudX = Math.sin(weatherAnimTick * 0.35) * 2
                            ctx.beginPath(); ctx.arc(12 + cloudX, 16, 7, Math.PI, Math.PI * 2); ctx.arc(20 + cloudX, 15, 8, Math.PI, Math.PI * 2); ctx.arc(26 + cloudX, 18, 5, Math.PI, Math.PI * 2); ctx.lineTo(29 + cloudX, 22); ctx.lineTo(6 + cloudX, 22); ctx.closePath(); ctx.fill()
                        } else {
                            ctx.strokeStyle = root.weatherIconColor; ctx.fillStyle = root.weatherIconColor
                            ctx.beginPath(); ctx.arc(18, 16, 8, 0, Math.PI * 2); ctx.fill()
                            for (var i = 0; i < 8; ++i) {
                                var a = i * Math.PI / 4 + weatherAnimTick * 0.08
                                ctx.beginPath(); ctx.moveTo(18 + Math.cos(a) * 11, 16 + Math.sin(a) * 11); ctx.lineTo(18 + Math.cos(a) * 15, 16 + Math.sin(a) * 15); ctx.stroke()
                            }
                        }
                        ctx.shadowBlur = 0
                    }
                    property string mode: root.weatherMode
                    property color iconColor: root.weatherIconColor
                    onModeChanged: requestPaint()
                    onIconColorChanged: requestPaint()
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
                    color: root.weatherIconColor; font.pixelSize: 18; font.bold: true; font.family: "Courier New"
                    style: Text.Outline; styleColor: root.weatherPanelColor
                }
            }
        }
    }
}

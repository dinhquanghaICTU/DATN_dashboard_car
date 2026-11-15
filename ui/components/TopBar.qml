import QtQuick 2.15

Item {
    id: root
    width: 800
    height: 44
    implicitWidth: 800
    implicitHeight: 44

    property bool introActive: false
    property color bgColor: "#080c12"
    property color primary: "#00e5cc"
    property color topPanelColor: Qt.rgba(0, 0.55, 0.48, 0.35)
    property color weatherPanelColor: "#101827"
    property color weatherIconColor: "#ff4fd8"
    property string weatherMode: "rain"

    // Background bar
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        color: "transparent"

        // 1. Digital Clock (Left)
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                text: Qt.formatTime(new Date(), "hh:mm")
                color: "#f8fafc"
                font.pixelSize: 22
                font.bold: true
                font.family: "Courier New"
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                text: Qt.formatTime(new Date(), "ss")
                color: root.primary
                font.pixelSize: 13
                font.bold: true
                font.family: "Courier New"
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: parent.text = Qt.formatTime(new Date(), "ss")
                }
            }
        }

        // 2. Date with Calendar Icon (Center)
        Row {
            anchors.centerIn: parent
            spacing: 8

            // Calendar Icon
            Canvas {
                id: calIcon
                width: 16
                height: 16
                anchors.verticalCenter: parent.verticalCenter
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = root.primary
                    ctx.fillStyle = root.primary
                    ctx.lineWidth = 1.5
                    ctx.strokeRect(2, 3, 12, 11)
                    ctx.beginPath()
                    ctx.moveTo(2, 7)
                    ctx.lineTo(14, 7)
                    ctx.stroke()
                    ctx.fillRect(4, 1, 2, 3)
                    ctx.fillRect(10, 1, 2, 3)
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(new Date(), "ddd, dd MMM yyyy").toUpperCase()
                color: root.primary
                font.pixelSize: 13
                font.bold: true
                font.family: "Courier New"
                font.letterSpacing: 1
                Timer {
                    interval: 60000
                    running: true
                    repeat: true
                    onTriggered: parent.text = Qt.formatDate(new Date(), "ddd, dd MMM yyyy").toUpperCase()
                }
            }
        }

        // 3. Weather Pill (Right) - (User specifically requested: "bỏ cái chữ ble đi", keeping only weather!)
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 108
            height: 28
            radius: 14
            color: "#181226"
            border.color: root.weatherIconColor
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: 6

                // Animated Weather Icon
                Canvas {
                    id: weatherIcon
                    width: 24
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter
                    property int animTick: 0
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.fillStyle = root.weatherIconColor
                        ctx.strokeStyle = root.weatherIconColor
                        ctx.lineWidth = 2
                        ctx.lineCap = "round"

                        // Cloud
                        ctx.beginPath()
                        ctx.arc(8, 8, 5, Math.PI, Math.PI * 2)
                        ctx.arc(15, 8, 4, Math.PI, Math.PI * 2)
                        ctx.lineTo(19, 12)
                        ctx.lineTo(3, 12)
                        ctx.closePath()
                        ctx.fill()

                        // Rain drops
                        for (var i = 0; i < 3; i++) {
                            var yOffset = (animTick + i * 2) % 4
                            ctx.beginPath()
                            ctx.moveTo(6 + i * 5, 14 + yOffset)
                            ctx.lineTo(4 + i * 5, 17 + yOffset)
                            ctx.stroke()
                        }
                    }

                    Timer {
                        interval: 180
                        running: true
                        repeat: true
                        onTriggered: {
                            weatherIcon.animTick = (weatherIcon.animTick + 1) % 100
                            weatherIcon.requestPaint()
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "RAIN"
                    color: root.weatherIconColor
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "Courier New"
                }
            }
        }
    }
}

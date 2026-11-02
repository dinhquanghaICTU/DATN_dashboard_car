import QtQuick 2.15

// Left column: phone-style battery + engine temperature, theme picker.
Item {
    id: root
    width: 220
    height: 406

    property int themeIndex: 0
    property string themeName: "AQUA"
    property color bgColor: "#060a10"
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color warningColor: "#ffcc00"
    property color dangerColor: "#ff4444"
    property color displayTempColor: "#ffaa00"
    property real batteryLevel: 100.0
    property bool batteryCriticalVisible: true
    property real temperature: 0
    property bool temperatureHazardLocked: false

    signal applyTheme(int index)
    signal nextTheme()

    readonly property string fontFamily: "DejaVu Sans"
    readonly property real batteryPct: Math.max(0, Math.min(batteryLevel / 100.0, 1))
    readonly property color batteryColor: batteryLevel > 50 ? accent : batteryLevel > 20 ? warningColor : dangerColor
    readonly property var themeSwatches: ["#00e5cc", "#58d68d", "#ffb347"]
    readonly property real tempMin: 20
    readonly property real tempMax: 80
    readonly property real tempLimit: 50
    function tempPct(t) { return Math.min(Math.max((t - tempMin) / (tempMax - tempMin), 0), 1) }

    // ------------------------------------------------------- Battery + temp
    DashCard {
        id: mainCard
        y: 0; width: parent.width; height: 326
        title: "BATTERY"
        accentColor: root.temperatureHazardLocked ? root.dangerColor : root.batteryColor
        alert: root.batteryLevel < 10.0 || root.temperatureHazardLocked

        // Phone-style battery
        Item {
            id: battery
            width: 160; height: 72
            anchors.horizontalCenter: parent.horizontalCenter
            y: 40
            opacity: root.batteryCriticalVisible ? 1.0 : 0.25

            // fake glow
            Rectangle {
                x: -4; y: -4; width: body.width + 8; height: body.height + 8; radius: 18
                color: "transparent"
                border.width: 4
                border.color: Qt.rgba(root.batteryColor.r, root.batteryColor.g, root.batteryColor.b, 0.18)
            }
            Rectangle {
                id: body
                width: 148; height: 72; radius: 14
                color: Qt.rgba(root.batteryColor.r, root.batteryColor.g, root.batteryColor.b, 0.06)
                border.width: 3
                border.color: root.batteryColor

                Rectangle {
                    x: 7; y: 7; height: parent.height - 14; radius: 8
                    width: Math.max(0, (parent.width - 14) * root.batteryPct)
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(root.batteryColor.r, root.batteryColor.g, root.batteryColor.b, 0.55) }
                        GradientStop { position: 1.0; color: root.batteryColor }
                    }
                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }
                Text {
                    anchors.centerIn: parent
                    text: root.batteryLevel.toFixed(0) + "%"
                    color: root.batteryPct >= 0.6 ? root.bgColor : "white"
                    font.family: root.fontFamily; font.pixelSize: 28; font.bold: true
                }
            }
            Rectangle {
                x: body.width + 3; width: 8; height: 26; radius: 3
                anchors.verticalCenter: body.verticalCenter
                color: root.batteryColor
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: battery.y + battery.height + 14
            text: root.batteryLevel > 50 ? "GOOD" : root.batteryLevel > 20 ? "MEDIUM" : root.batteryLevel >= 10 ? "LOW" : "CRITICAL"
            color: root.batteryColor
            opacity: root.batteryCriticalVisible ? 0.9 : 0.25
            font.family: root.fontFamily; font.pixelSize: 10; font.bold: true; font.letterSpacing: 2
        }

        Rectangle { x: 14; y: 160; width: parent.width - 28; height: 1; color: Qt.rgba(1, 1, 1, 0.08) }

        // Engine temperature
        Row {
            x: 14; y: 176; spacing: 7
            Canvas {
                id: thermo
                width: 12; height: 16
                anchors.verticalCenter: parent.verticalCenter
                property color tone: root.displayTempColor
                onToneChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = tone; ctx.fillStyle = tone; ctx.lineWidth = 1.6
                    ctx.beginPath(); ctx.roundedRect(3.5, 1, 5, 10, 2.5, 2.5); ctx.stroke()
                    ctx.beginPath(); ctx.arc(6, 12, 3.5, 0, Math.PI * 2); ctx.fill()
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "ENGINE TEMP"
                color: Qt.rgba(1, 1, 1, 0.55)
                font.family: root.fontFamily; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.6
            }
        }
        Row {
            x: 14; y: 198
            Text {
                id: tempValue
                text: root.temperature.toFixed(1)
                color: root.displayTempColor
                font.family: root.fontFamily; font.pixelSize: 32; font.bold: true
            }
            Text {
                anchors.baseline: tempValue.baseline
                text: " °C"
                color: Qt.rgba(1, 1, 1, 0.5)
                font.family: root.fontFamily; font.pixelSize: 14; font.bold: true
            }
        }

        Item {
            id: tempBar
            x: 14; y: 252; width: parent.width - 28; height: 8
            Rectangle { anchors.fill: parent; radius: 4; color: Qt.rgba(1, 1, 1, 0.07) }
            Rectangle {
                width: Math.max(height, root.tempPct(root.temperature) * parent.width); height: parent.height; radius: 4
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(root.displayTempColor.r, root.displayTempColor.g, root.displayTempColor.b, 0.45) }
                    GradientStop { position: 1.0; color: root.displayTempColor }
                }
                Behavior on width { NumberAnimation { duration: 200 } }
            }
            Rectangle {
                x: root.tempPct(root.tempLimit) * parent.width - 1; y: -3
                width: 2; height: parent.height + 6; radius: 1
                color: Qt.rgba(root.dangerColor.r, root.dangerColor.g, root.dangerColor.b, 0.8)
            }
        }
        Item {
            x: tempBar.x; y: tempBar.y + 14; width: tempBar.width; height: 12
            Repeater {
                model: [root.tempMin, root.tempLimit, root.tempMax]
                Text {
                    x: root.tempPct(modelData) * parent.width - (index === 0 ? 0 : index === 2 ? width : width / 2)
                    text: modelData + "°"
                    color: index === 1 ? Qt.rgba(root.dangerColor.r, root.dangerColor.g, root.dangerColor.b, 0.8) : Qt.rgba(1, 1, 1, 0.35)
                    font.family: root.fontFamily; font.pixelSize: 9; font.bold: true
                }
            }
        }
        Text {
            x: 14; y: 296
            text: root.temperatureHazardLocked ? "OVERHEAT · HAZARD ON" : "NORMAL"
            color: root.temperatureHazardLocked ? root.dangerColor : Qt.rgba(1, 1, 1, 0.45)
            font.family: root.fontFamily; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.4
        }
    }

    // ------------------------------------------------------------------ Theme
    DashCard {
        y: mainCard.y + mainCard.height + 10
        width: parent.width; height: parent.height - y
        accentColor: root.primary

        Row {
            x: 12; anchors.verticalCenter: parent.verticalCenter
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
            anchors.verticalCenter: parent.verticalCenter
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

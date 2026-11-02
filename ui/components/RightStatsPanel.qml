import QtQuick 2.15

Item {
    id: root
    width: 220
    height: 406

    property bool introActive: false
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color rpmColor: "#9966ff"
    property color dangerColor: "#ff4444"
    property color warningColor: "#ffcc00"
    property color displayTempColor: "#ffaa00"
    property real displaySpeed: 0
    property real displayRpm: 0
    property real temperature: 0
    property bool temperatureHazardLocked: false
    property bool bleConnected: false

    readonly property string fontFamily: "DejaVu Sans"
    readonly property real tempMin: 20
    readonly property real tempMax: 80
    readonly property real tempLimit: 50
    function tempPct(t) { return Math.min(Math.max((t - tempMin) / (tempMax - tempMin), 0), 1) }

    // ------------------------------------------------------------ Engine temp
    DashCard {
        id: tempCard
        y: 0; width: parent.width; height: 150
        title: "ENGINE TEMP"
        accentColor: root.displayTempColor
        alert: root.temperatureHazardLocked

        Row {
            x: 14; y: 32
            Text {
                id: tempValue
                text: root.temperature.toFixed(1)
                color: root.displayTempColor
                font.family: root.fontFamily; font.pixelSize: 34; font.bold: true
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
            x: 14; y: 88; width: parent.width - 28; height: 8
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
            x: 14; y: 124
            text: root.temperatureHazardLocked ? "OVERHEAT · HAZARD ON" : "NORMAL"
            color: root.temperatureHazardLocked ? root.dangerColor : Qt.rgba(1, 1, 1, 0.45)
            font.family: root.fontFamily; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.4
        }
    }

    // ------------------------------------------------------------------ Motor
    DashCard {
        id: motorCard
        y: tempCard.y + tempCard.height + 12
        width: parent.width; height: 132
        title: "MOTOR"
        accentColor: root.rpmColor

        Row {
            x: 14; y: 30
            Text {
                id: rpmText
                text: root.displayRpm.toFixed(0)
                color: root.rpmColor
                font.family: root.fontFamily; font.pixelSize: 34; font.bold: true
            }
            Text {
                anchors.baseline: rpmText.baseline
                text: " rpm"
                color: Qt.rgba(1, 1, 1, 0.5)
                font.family: root.fontFamily; font.pixelSize: 13; font.bold: true
            }
        }
        Rectangle { x: 14; y: 84; width: parent.width - 28; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }
        Text {
            x: 14; y: 98
            text: "WHEEL SPEED"
            color: Qt.rgba(1, 1, 1, 0.4)
            font.family: root.fontFamily; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.4
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 14; y: 94
            text: root.displaySpeed.toFixed(2) + " m/s"
            color: "white"
            font.family: root.fontFamily; font.pixelSize: 15; font.bold: true
        }
    }

    // ------------------------------------------------------------------- BLE
    DashCard {
        y: motorCard.y + motorCard.height + 12
        width: parent.width; height: parent.height - y
        title: "BLE LINK"
        accentColor: root.bleConnected ? root.accent : Qt.rgba(1, 1, 1, 0.35)

        Item {
            id: bleDot
            x: 18; y: 50; width: 22; height: 22
            Rectangle {
                anchors.centerIn: parent
                width: 22; height: 22; radius: 11
                color: "transparent"
                border.width: 2
                border.color: root.bleConnected ? root.accent : Qt.rgba(1, 1, 1, 0.25)
                opacity: 0.5
                SequentialAnimation on scale {
                    running: root.bleConnected && !root.introActive
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.6; to: 1.2; duration: 1200; easing.type: Easing.OutCubic }
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: 10; height: 10; radius: 5
                color: root.bleConnected ? root.accent : Qt.rgba(1, 1, 1, 0.3)
            }
        }
        Column {
            anchors.left: bleDot.right; anchors.leftMargin: 14
            anchors.verticalCenter: bleDot.verticalCenter
            spacing: 2
            Text {
                text: root.bleConnected ? "CONNECTED" : "WAITING…"
                color: root.bleConnected ? root.accent : Qt.rgba(1, 1, 1, 0.6)
                font.family: root.fontFamily; font.pixelSize: 17; font.bold: true; font.letterSpacing: 1
            }
            Text {
                text: "Mobile controller"
                color: Qt.rgba(1, 1, 1, 0.38)
                font.family: root.fontFamily; font.pixelSize: 10
            }
        }
    }
}

import QtQuick 2.15

Item {
    id: root
    width: 220
    height: 416

    property int themeIndex: 0
    property string themeName: "AQUA"
    property color primary: "#00e5cc"
    property color accent: "#00ff88"
    property color cardBg: "#0a101d"
    property color cardBorder: Qt.rgba(1, 1, 1, 0.08)
    property color warningColor: "#ffcc00"
    property color dangerColor: "#ff4444"
    property color tempColor: "#ffaa00"
    property color displayTempColor: tempColor
    property real batteryLevel: 100.0
    property bool batteryCriticalVisible: true
    property real temperature: 38.5

    signal applyTheme(int index)
    signal nextTheme()

    Column {
        anchors.fill: parent
        spacing: 12

        // ================= CARD 1: BATTERY =================
        Rectangle {
            width: parent.width
            height: 156
            radius: 16
            color: root.cardBg
            border.color: root.cardBorder
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header
                Row {
                    spacing: 6
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: root.batteryLevel > 20 ? "#00e676" : root.dangerColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "BATTERY"
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "Courier New"
                        font.letterSpacing: 1
                    }
                }

                // Battery Graphic Body
                Item {
                    width: parent.width
                    height: 72

                    // Battery Terminal Nub (Right side)
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 22
                        radius: 2
                        color: root.batteryLevel > 20 ? "#00e676" : root.dangerColor
                    }

                    // Main Battery Frame
                    Rectangle {
                        id: batteryFrame
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        height: 60
                        radius: 10
                        color: "#0d1825"
                        border.color: root.batteryLevel > 20 ? "#00e676" : root.dangerColor
                        border.width: 2.5

                        // Inner Battery Level Fill
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 4
                            width: (parent.width - 8) * Math.min(Math.max(root.batteryLevel / 100.0, 0.05), 1.0)
                            radius: 6
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: root.batteryLevel > 50 ? "#00c853" : root.batteryLevel > 20 ? root.warningColor : root.dangerColor }
                                GradientStop { position: 1.0; color: root.batteryLevel > 50 ? "#69f0ae" : root.batteryLevel > 20 ? "#ffd54f" : "#ff5252" }
                            }
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }

                        // Percentage Text inside battery
                        Text {
                            anchors.centerIn: parent
                            text: root.batteryLevel.toFixed(0) + "%"
                            color: "#08101a"
                            font.pixelSize: 26
                            font.bold: true
                            font.family: "Courier New"
                        }
                    }
                }

                // Subtitle Status
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.batteryLevel > 50 ? "GOOD" : root.batteryLevel > 20 ? "MODERATE" : "LOW BATTERY"
                    color: root.batteryLevel > 50 ? "#00e676" : root.batteryLevel > 20 ? root.warningColor : root.dangerColor
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Courier New"
                    font.letterSpacing: 2
                }
            }
        }

        // ================= CARD 2: ENGINE TEMP =================
        Rectangle {
            width: parent.width
            height: 172
            radius: 16
            color: root.cardBg
            border.color: root.cardBorder
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header
                Row {
                    spacing: 6
                    Text {
                        text: "🌡️"
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "ENGINE TEMP"
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "Courier New"
                        font.letterSpacing: 1
                    }
                }

                // Temperature Value Display
                Row {
                    spacing: 4
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    Text {
                        text: root.temperature.toFixed(1)
                        color: root.temperature > 50 ? root.dangerColor : root.tempColor
                        font.pixelSize: 34
                        font.bold: true
                        font.family: "Courier New"
                    }
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        text: "°C"
                        color: root.temperature > 50 ? root.dangerColor : root.tempColor
                        font.pixelSize: 16
                        font.bold: true
                        font.family: "Courier New"
                    }
                }

                // Horizontal Gauge Bar
                Item {
                    width: parent.width - 8
                    height: 24
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Track background
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 8
                        radius: 4
                        color: "#182232"

                        // Active Progress Fill
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.min(Math.max((root.temperature - 20) / 60.0, 0.05), 1.0)
                            radius: 4
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#ff9100" }
                                GradientStop { position: 0.7; color: "#ff6d00" }
                                GradientStop { position: 1.0; color: root.temperature > 50 ? root.dangerColor : "#ff9100" }
                            }
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }

                        // 50 degree red warning tick line
                        Rectangle {
                            x: parent.width * 0.5 - 1
                            y: -2
                            width: 2
                            height: 12
                            color: root.dangerColor
                        }
                    }

                    // Gauge scale labels
                    Item {
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 12

                        Text {
                            anchors.left: parent.left
                            text: "20°"
                            color: Qt.rgba(1, 1, 1, 0.3)
                            font.pixelSize: 9
                            font.family: "Courier New"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "50°"
                            color: root.dangerColor
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Courier New"
                        }
                        Text {
                            anchors.right: parent.right
                            text: "80°"
                            color: Qt.rgba(1, 1, 1, 0.3)
                            font.pixelSize: 9
                            font.family: "Courier New"
                        }
                    }
                }

                // Subtitle Status
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    text: root.temperature > 50.0 ? "OVERHEAT" : "NORMAL"
                    color: root.temperature > 50.0 ? root.dangerColor : Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Courier New"
                    font.letterSpacing: 2
                }
            }
        }

        // ================= BOTTOM: THEME SELECTOR =================
        Rectangle {
            width: parent.width
            height: 52
            radius: 16
            color: root.cardBg
            border.color: root.cardBorder
            border.width: 1

            TapHandler {
                onTapped: {
                    console.log("[Theme] Background tapped -> nextTheme")
                    root.nextTheme()
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[Theme] Background clicked -> nextTheme")
                    root.nextTheme()
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 6
                z: 10

                // Dot 1: Cyan (AQUA)
                Item {
                    width: 36; height: 44
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        anchors.centerIn: parent
                        width: 22; height: 22; radius: 11
                        color: "transparent"
                        border.color: root.themeIndex === 0 ? "#00e5cc" : "transparent"
                        border.width: 2
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 14; height: 14; radius: 7
                        color: "#00e5cc"
                    }
                    TapHandler {
                        onTapped: {
                            console.log("[Theme] Dot 0 (AQUA) tapped")
                            root.applyTheme(0)
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("[Theme] Dot 0 (AQUA) clicked")
                            root.applyTheme(0)
                        }
                    }
                }

                // Dot 2: Green (FOREST)
                Item {
                    width: 36; height: 44
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        anchors.centerIn: parent
                        width: 22; height: 22; radius: 11
                        color: "transparent"
                        border.color: root.themeIndex === 1 ? "#58d68d" : "transparent"
                        border.width: 2
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 14; height: 14; radius: 7
                        color: "#58d68d"
                    }
                    TapHandler {
                        onTapped: {
                            console.log("[Theme] Dot 1 (FOREST) tapped")
                            root.applyTheme(1)
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("[Theme] Dot 1 (FOREST) clicked")
                            root.applyTheme(1)
                        }
                    }
                }

                // Dot 3: Amber (AMBER)
                Item {
                    width: 36; height: 44
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        anchors.centerIn: parent
                        width: 22; height: 22; radius: 11
                        color: "transparent"
                        border.color: root.themeIndex === 2 ? "#ffb347" : "transparent"
                        border.width: 2
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 14; height: 14; radius: 7
                        color: "#ffb347"
                    }
                    TapHandler {
                        onTapped: {
                            console.log("[Theme] Dot 2 (AMBER) tapped")
                            root.applyTheme(2)
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("[Theme] Dot 2 (AMBER) clicked")
                            root.applyTheme(2)
                        }
                    }
                }

                // Theme Name Badge
                Item {
                    width: 64; height: 44
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: root.themeName
                        color: root.primary
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "Courier New"
                        font.letterSpacing: 2
                    }
                    TapHandler {
                        onTapped: {
                            console.log("[Theme] Text tapped -> nextTheme")
                            root.nextTheme()
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("[Theme] Text clicked -> nextTheme")
                            root.nextTheme()
                        }
                    }
                }
            }
        }
    }
}

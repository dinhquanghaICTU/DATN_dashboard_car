import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    visible: true
    width: 800
    height: 480
    color: "#1a1a2e"

    Rectangle {
        width: 12; height: 12; radius: 6
        color: vehicle.bleConnected ? "#00ff88" : "#ff4444"
        anchors { top: parent.top; right: parent.right; margins: 20 }
    }

    Text {
        text: vehicle.bleConnected ? "BLE Connected" : "Waiting BLE..."
        color: vehicle.bleConnected ? "#00ff88" : "#888888"
        font.pixelSize: 14
        anchors { top: parent.top; right: parent.right; topMargin: 16; rightMargin: 40 }
    }

    Text {
        text: vehicle.speed.toFixed(1) + " m/s"
        color: "white"
        font.pixelSize: 64
        font.bold: true
        anchors.centerIn: parent
    }

    Text {
        text: vehicle.rpm.toFixed(0) + " RPM"
        color: "#aaaaaa"
        font.pixelSize: 24
        anchors {
            top: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
            topMargin: 40
        }
    }
    Text {
        text: vehicle.temperature.toFixed(1) + " °C"
        color: "#ffaa00"
        font.pixelSize: 24
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 40
        }
    }
}

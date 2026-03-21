import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    visible: true
    width: 800; height: 480
    color: "#1a1a2e"

    // Trạng thái BLE
    Rectangle {
        width: 12; height: 12; radius: 6
        color: bleServer.connected ? "#00ff88" : "#ff4444"
        anchors { top: parent.top; right: parent.right; margins: 20 }
    }

    Text {
        text: bleServer.connected ? "BLE Connected" : "Waiting BLE..."
        color: bleServer.connected ? "#00ff88" : "#888888"
        font.pixelSize: 14
        anchors { top: parent.top; right: parent.right; topMargin: 16; rightMargin: 40 }
    }

    // Hiển thị tốc độ
    Text {
        text: speedSensor.speed.toFixed(1) + " m/s"
        color: "white"
        font.pixelSize: 64
        font.bold: true
        anchors.centerIn: parent
    }

    Text {
        text: speedSensor.rpm.toFixed(0) + " RPM"
        color: "#aaaaaa"
        font.pixelSize: 24
        anchors { top: parent.verticalCenter; horizontalCenter: parent.horizontalCenter; topMargin: 40 }
    }
}

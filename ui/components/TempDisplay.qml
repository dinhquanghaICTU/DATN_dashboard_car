import QtQuick 2.15

Item {
    id: root
    width: 200
    height: 100

    property real temperature: 0

    Text {
        anchors.centerIn: parent
        text: temperature.toFixed(1) + " °C"
        color: "white"
        font.pixelSize: 20
    }
}

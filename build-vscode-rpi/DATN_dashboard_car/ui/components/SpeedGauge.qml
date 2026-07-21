import QtQuick 2.15

Item {
    id: root
    width: 200
    height: 200

    property real rpm: 0
    property real speed: 0

    Text {
        anchors.centerIn: parent
        text: speed.toFixed(1) + " m/s"
        color: "white"
        font.pixelSize: 20
    }
}

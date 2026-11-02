import QtQuick 2.15

// Shared "glass" card used by the side panels.
Rectangle {
    id: card

    property string title: ""
    property color accentColor: "white"
    property bool alert: false

    radius: 16
    color: alert ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.08) : Qt.rgba(1, 1, 1, 0.035)
    border.width: 1
    border.color: alert ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.6) : Qt.rgba(1, 1, 1, 0.08)
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    Row {
        visible: card.title !== ""
        x: 14; y: 12; spacing: 7
        Rectangle {
            width: 6; height: 6; radius: 3
            color: card.accentColor
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: card.title
            color: Qt.rgba(1, 1, 1, 0.55)
            font.family: "DejaVu Sans"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.6
        }
    }
}

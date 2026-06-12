import QtQuick 2.15
import QtMultimedia

Item {
    id: root
    anchors.fill: parent

    property bool introActive: true
    signal finished()

    function finishIntro() {
        if (root.introActive) root.finished()
    }

    MediaPlayer {
        id: introPlayer
        source: "qrc:/DATN_dashboard_car/assets/intro.mp4"
        videoOutput: introOutput
        audioOutput: AudioOutput { muted: true }
        Component.onCompleted: play()
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) root.finishIntro()
        }
        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.StoppedState) root.finishIntro()
        }
        onErrorOccurred: root.finishIntro()
    }

    VideoOutput {
        id: introOutput
        anchors.fill: parent
        visible: root.introActive
        opacity: root.introActive ? 1.0 : 0.0
        fillMode: VideoOutput.PreserveAspectCrop
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Timer {
        interval: 9000
        running: root.introActive
        repeat: false
        onTriggered: root.finishIntro()
    }

    Rectangle {
        anchors.fill: parent
        visible: root.introActive && introPlayer.playbackState !== MediaPlayer.PlayingState
        color: "black"
    }
}

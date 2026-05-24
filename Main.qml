import QtQuick 2.15
import QtQuick.Window 2.15
import QtMultimedia

Window {
    id: root
    visible: true
    width: 800
    height: 480
    minimumWidth: 800
    maximumWidth: 800
    minimumHeight: 480
    maximumHeight: 480
    color: bgColor
    title: "DATN Dashboard"
    property bool introActive: true

    property int themeIndex: 0
    property string themeName: themeIndex === 0 ? "AQUA" : themeIndex === 1 ? "FOREST" : "AMBER"
    property color bgColor: themeIndex === 0 ? "#080c12" : themeIndex === 1 ? "#07100c" : "#100d08"
    property color primaryLine: themeIndex === 0 ? Qt.rgba(0,0.9,0.8,0.12) : themeIndex === 1 ? Qt.rgba(0.35,0.84,0.55,0.12) : Qt.rgba(1.0,0.7,0.28,0.12)
    property color primaryBorder: themeIndex === 0 ? Qt.rgba(0,0.9,0.8,0.15) : themeIndex === 1 ? Qt.rgba(0.35,0.84,0.55,0.15) : Qt.rgba(1.0,0.7,0.28,0.15)
    property color rpmBorder: themeIndex === 0 ? Qt.rgba(0.6,0.4,1,0.2) : themeIndex === 1 ? Qt.rgba(0.49,0.78,1,0.2) : Qt.rgba(1,0.56,0.44,0.2)
    property color tempBorder: themeIndex === 0 ? Qt.rgba(1,0.67,0,0.2) : themeIndex === 1 ? Qt.rgba(1,0.82,0.4,0.2) : Qt.rgba(1,0.62,0.11,0.2)
    property color accentBorder: themeIndex === 0 ? Qt.rgba(0,1,0.5,0.2) : themeIndex === 1 ? Qt.rgba(0.72,0.95,0.78,0.2) : Qt.rgba(1,0.88,0.48,0.2)
    property color warningBorder: themeIndex === 0 ? Qt.rgba(1,0.8,0,0.2) : themeIndex === 1 ? Qt.rgba(0.96,0.82,0.37,0.2) : Qt.rgba(1,0.8,0.4,0.2)
    property color primary: themeIndex === 0 ? "#00e5cc" : themeIndex === 1 ? "#58d68d" : "#ffb347"
    property color accent: themeIndex === 0 ? "#00ff88" : themeIndex === 1 ? "#b8f2c8" : "#ffe17a"
    property color speedColor: themeIndex === 0 ? "#00d4ff" : themeIndex === 1 ? "#7ee8a7" : "#ffc857"
    property color rpmColor: themeIndex === 0 ? "#9966ff" : themeIndex === 1 ? "#7cc7ff" : "#ff8f70"
    property color tempColor: themeIndex === 0 ? "#ffaa00" : themeIndex === 1 ? "#ffd166" : "#ff9f1c"
    property color warningColor: themeIndex === 0 ? "#ffcc00" : themeIndex === 1 ? "#f4d35e" : "#ffcc66"
    property color dangerColor: "#ff4444"
    property color mutedWhite: Qt.rgba(1,1,1,0.3)
    property var themedRepaintQueue: []
    property bool themeReloading: false
    property int pendingThemeIndex: -1

    function themedCanvases() {
        return [
            speedGaugeStaticCanvas, speedGaugeCanvas, batteryArc,
            leftSignalIcon, hazardIcon, rightSignalIcon, lampIcon,
            tempIconSmall, tempBarsLeft, speedCardIcon, rpmCardIcon,
            tempCardIcon, batteryCardIcon
        ]
    }

    function scheduleThemedRepaints() {
        themedRepaintQueue = themedCanvases()
        themedRepaintTimer.restart()
    }

    function repaintThemedCanvasesNow() {
        var canvases = themedCanvases()
        for (var i = 0; i < canvases.length; ++i) {
            if (canvases[i]) canvases[i].requestPaint()
        }
    }

    function applyTheme(index) {
        if (index === themeIndex && !themeReloading) return
        pendingThemeIndex = index
        themeReloading = true
        themeApplyTimer.restart()
    }

    onThemeIndexChanged: {
        if (themeReloading) {
            themedRepaintTimer.stop()
            themedRepaintQueue = []
            repaintThemedCanvasesNow()
        } else {
            scheduleThemedRepaints()
        }
    }

    property bool leftSignal:  ledCtrl.leftSignal
    property bool rightSignal: ledCtrl.rightSignal
    property bool headLight:   ledCtrl.headLight
    property int  signalTick:  0
    property real batteryLevel: 85.0
    property real displaySpeed: vehicle.speed
    property real displayRpm: vehicle.rpm
    property bool speedGaugeDirty: false

    function nextTheme() {
        applyTheme((themeIndex + 1) % 3)
    }

    function finishIntro() {
        if (!introActive) return
        introActive = false
    }

    Timer {
        interval: 500
        running: leftSignal || rightSignal
        repeat: true
        onTriggered: signalTick = (signalTick + 1) % 2
    }

    Timer {
        id: themedRepaintTimer
        interval: 16
        repeat: true
        onTriggered: {
            if (themedRepaintQueue.length === 0) {
                stop()
                return
            }
            var item = themedRepaintQueue.shift()
            if (item) item.requestPaint()
        }
    }

    Timer {
        id: themeApplyTimer
        interval: 35
        repeat: false
        onTriggered: {
            if (pendingThemeIndex >= 0) {
                themeIndex = pendingThemeIndex
                pendingThemeIndex = -1
            }
            speedGaugeDirty = true
            themeRevealTimer.restart()
        }
    }

    Timer {
        id: themeRevealTimer
        interval: 90
        repeat: false
        onTriggered: themeReloading = false
    }

    onDisplaySpeedChanged: speedGaugeDirty = true
    Timer {
        interval: 80
        running: true
        repeat: true
        onTriggered: {
            if (!speedGaugeDirty) return
            speedGaugeDirty = false
            speedGaugeCanvas.requestPaint()
        }
    }

    Item {
        id: dashboard
        anchors.fill: parent
        visible: !introActive
        opacity: introActive ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    // Outer border
    Rectangle {
        anchors.fill: parent; color: "transparent"
        border.color: primary; border.width: 3; radius: 28; z: 100
    }

    // Top bar
    Rectangle {
        x: 3; y: 3; width: parent.width-6; height: 40
        color: primary; radius: 25
        Rectangle { x:0; y:20; width: parent.width; height:20; color:primary }
        Row {
            anchors.centerIn: parent; spacing: 40
            Text {
                text: Qt.formatTime(new Date(), "hh:mm")
                color: bgColor; font.pixelSize:16; font.bold:true; font.family:"Courier New"
                Timer { interval:1000; running:true; repeat:true; onTriggered: parent.text = Qt.formatTime(new Date(),"hh:mm") }
            }
            Text {
                text: Qt.formatDate(new Date(), "dd/MM/yyyy")
                color: bgColor; font.pixelSize:14; font.family:"Courier New"
            }
        }
    }

    // Separators
    Rectangle { x:246; y:52; width:1; height:390; color: primaryLine }
    Rectangle { x:parent.width-247; y:52; width:1; height:390; color: primaryLine }

   
    Item {
        x: 10; y: 52; width: 246; height: 400

        // Battery arc
        Canvas {
            id: batteryArc
            x: 23; y: 8; width: 200; height: 200
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0,0,width,height)
                var cx=100, cy=100, r=80
                ctx.beginPath(); ctx.arc(cx,cy,r,-Math.PI*0.8,Math.PI*0.8)
                ctx.strokeStyle="rgba(255,255,255,0.07)"; ctx.lineWidth=12; ctx.lineCap="round"; ctx.stroke()
                var pct = batteryLevel/100.0
                var grad = ctx.createLinearGradient(0,0,200,0)
                if(batteryLevel>50){ grad.addColorStop(0,primary); grad.addColorStop(1,accent) }
                else if(batteryLevel>20){ grad.addColorStop(0,warningColor); grad.addColorStop(1,tempColor) }
                else { grad.addColorStop(0,dangerColor); grad.addColorStop(1,"#ff0000") }
                ctx.beginPath(); ctx.arc(cx,cy,r,-Math.PI*0.8,-Math.PI*0.8+pct*Math.PI*1.6)
                ctx.strokeStyle=grad; ctx.lineWidth=12; ctx.lineCap="round"; ctx.stroke()
            }
            property real batt: batteryLevel
            onBattChanged: requestPaint()
        }
        Text {
            x:23; y:80; width:200
            text: batteryLevel.toFixed(0)+"%"
            color: batteryLevel>50?primary:batteryLevel>20?warningColor:dangerColor
            font.pixelSize:34; font.bold:true; font.family:"Courier New"
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            x:23; y:122; width:200
            text:"Battery"
            color: Qt.rgba(1,1,1,0.35); font.pixelSize:12; font.family:"Courier New"
            font.letterSpacing:2; horizontalAlignment: Text.AlignHCenter
        }

        Rectangle { x:20; y:216; width:206; height:1; color:Qt.rgba(1,1,1,0.07) }

        // Signal + light row
        Row {
            x:16; y:228; spacing:10

            Canvas {
                id: leftSignalIcon
                width:36; height:36
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                    ctx.fillStyle=(leftSignal&&signalTick===0)?accent:"rgba(255,255,255,0.1)"
                    ctx.beginPath(); ctx.moveTo(36,6); ctx.lineTo(16,18); ctx.lineTo(36,30); ctx.closePath(); ctx.fill()
                    ctx.beginPath(); ctx.moveTo(20,6); ctx.lineTo(0,18);  ctx.lineTo(20,30); ctx.closePath(); ctx.fill()
                }
                property bool ls:leftSignal; property int st:signalTick
                onLsChanged: requestPaint(); onStChanged: requestPaint()
                MouseArea { anchors.fill:parent; onClicked:ledCtrl.toggleLeftSignal() }
            }
            Canvas {
                id: hazardIcon
                width:36; height:36
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                    ctx.fillStyle=(leftSignal&&rightSignal)?warningColor:"rgba(255,255,255,0.1)"
                    ctx.beginPath(); ctx.moveTo(18,2); ctx.lineTo(34,32); ctx.lineTo(2,32); ctx.closePath(); ctx.fill()
                }
                property bool ls:leftSignal; property bool rs:rightSignal
                onLsChanged: requestPaint(); onRsChanged: requestPaint()
                MouseArea { anchors.fill:parent; onClicked:ledCtrl.toggleHazard() }
            }
            Canvas {
                id: rightSignalIcon
                width:36; height:36
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                    ctx.fillStyle=(rightSignal&&signalTick===0)?accent:"rgba(255,255,255,0.1)"
                    ctx.beginPath(); ctx.moveTo(0,6);  ctx.lineTo(20,18); ctx.lineTo(0,30);  ctx.closePath(); ctx.fill()
                    ctx.beginPath(); ctx.moveTo(14,6); ctx.lineTo(34,18); ctx.lineTo(14,30); ctx.closePath(); ctx.fill()
                }
                property bool rs:rightSignal; property int st:signalTick
                onRsChanged: requestPaint(); onStChanged: requestPaint()
                MouseArea { anchors.fill:parent; onClicked:ledCtrl.toggleRightSignal() }
            }
            Canvas {
                id: lampIcon
                width:36; height:36
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                    ctx.strokeStyle=headLight?accent:"rgba(255,255,255,0.15)"
                    ctx.lineWidth=2
                    ctx.beginPath(); ctx.arc(18,18,9,0,Math.PI*2); ctx.stroke()
                    for(var i=0;i<6;i++){
                        var a=(i/6)*Math.PI*2
                        ctx.beginPath(); ctx.moveTo(18+Math.cos(a)*11,18+Math.sin(a)*11)
                        ctx.lineTo(18+Math.cos(a)*16,18+Math.sin(a)*16); ctx.stroke()
                    }
                }
                property bool hl:headLight
                onHlChanged: requestPaint()
                MouseArea { anchors.fill:parent; onClicked:ledCtrl.toggleHeadLight() }
            }
            Canvas {
                id: tempIconSmall
                width:36; height:36
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                    // Thermometer icon
                    ctx.strokeStyle=tempColor; ctx.lineWidth=2
                    ctx.beginPath(); ctx.moveTo(14,4); ctx.lineTo(14,26); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(22,4); ctx.lineTo(22,26); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(14,4); ctx.arc(18,4,4,-Math.PI,0); ctx.stroke()
                    ctx.beginPath(); ctx.arc(18,30,6,0,Math.PI*2)
                    ctx.fillStyle=tempColor; ctx.fill()
                    // fill
                    var pct=Math.min(Math.max((vehicle.temperature-20)/60,0),1)
                    ctx.fillStyle=tempColor
                    ctx.fillRect(15,26-pct*20,6,pct*20)
                }
                property real tmp:vehicle.temperature
                onTmpChanged: requestPaint()
            }
        }

        Row {
            x:16; y:270; spacing:10
            Text { width:36; text:"L";    color:Qt.rgba(1,1,1,0.2); font.pixelSize:9; font.family:"Courier New"; horizontalAlignment:Text.AlignHCenter }
            Text { width:36; text:"HAZ";  color:Qt.rgba(1,1,1,0.2); font.pixelSize:9; font.family:"Courier New"; horizontalAlignment:Text.AlignHCenter }
            Text { width:36; text:"R";    color:Qt.rgba(1,1,1,0.2); font.pixelSize:9; font.family:"Courier New"; horizontalAlignment:Text.AlignHCenter }
            Text { width:36; text:"LAMP"; color:Qt.rgba(1,1,1,0.2); font.pixelSize:9; font.family:"Courier New"; horizontalAlignment:Text.AlignHCenter }
            Text { width:36; text:"TEMP"; color:Qt.rgba(1,1,1,0.2); font.pixelSize:9; font.family:"Courier New"; horizontalAlignment:Text.AlignHCenter }
        }

        Row {
            x:14; y:284; spacing:8
            Repeater {
                model: 3
                Item {
                    width: 36; height: 36
                    Rectangle {
                        anchors.centerIn: parent
                        width: themeIndex === index ? 32 : 28
                        height: width
                        radius: width / 2
                        color: index === 0 ? "#00e5cc" : index === 1 ? "#58d68d" : "#ffb347"
                        border.color: themeIndex === index ? "white" : Qt.rgba(1,1,1,0.18)
                        border.width: themeIndex === index ? 3 : 1
                        Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: applyTheme(index)
                    }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: themeName
                color: Qt.rgba(1,1,1,0.38)
                font.pixelSize: 14; font.family: "Courier New"; font.bold: true; font.letterSpacing: 2
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    onClicked: nextTheme()
                }
            }
        }

        // Temp value
        Row {
            x:14; y:338; spacing:10
            Canvas {
                id: tempBarsLeft
                width:28; height:40
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                    // signal bars
                    var pct=Math.min(Math.max((vehicle.temperature-20)/60,0),1)
                    var bars=Math.ceil(pct*4)
                    for(var i=0;i<4;i++){
                        var bh=6+i*6; var bx=i*7
                        ctx.fillStyle=i<bars?tempColor:"rgba(255,255,255,0.1)"
                        ctx.fillRect(bx,34-bh,5,bh)
                    }
                }
                property real tmp:vehicle.temperature; onTmpChanged:requestPaint()
            }
            Column {
                spacing:2
                Text { text:vehicle.temperature.toFixed(1)+"°C"; color:tempColor; font.pixelSize:22; font.bold:true; font.family:"Courier New" }
                Text { text:"Engine Temp"; color:Qt.rgba(1,1,1,0.3); font.pixelSize:10; font.family:"Courier New" }
            }
        }
    }

    
    Item {
        x: 246; y: 48
        width: parent.width - 492; height: 432

        
        Canvas {
            id: speedGaugeStaticCanvas
            x:10; y:4; width:parent.width-20; height:280
            onPaint: {
                var ctx=getContext("2d")
                ctx.clearRect(0,0,width,height)
                var cx=width/2, cy=172, r=112
                var startA=Math.PI*0.72
                ctx.beginPath(); ctx.arc(cx,cy,r,Math.PI*0.72,Math.PI*2.28)
                ctx.strokeStyle="rgba(255,255,255,0.06)"; ctx.lineWidth=18; ctx.lineCap="round"; ctx.stroke()
                for(var i=0;i<=12;i++){
                    var a=startA+(i/12)*Math.PI*1.56
                    ctx.strokeStyle=i%4===0?"rgba(255,255,255,0.6)":"rgba(255,255,255,0.2)"
                    ctx.lineWidth=i%4===0?2.5:1.2
                    var r1=r+12, r2=i%4===0?r+30:r+22
                    ctx.beginPath()
                    ctx.moveTo(cx+Math.cos(a)*r1,cy+Math.sin(a)*r1)
                    ctx.lineTo(cx+Math.cos(a)*r2,cy+Math.sin(a)*r2)
                    ctx.stroke()
                }
                ctx.fillStyle="rgba(255,255,255,0.4)"; ctx.font="12px Courier New"
                ctx.textAlign="center"
                var labels=["0","","","1","","","2","","","3","","",""]
                for(var j=0;j<=12;j++){
                    var la=startA+(j/12)*Math.PI*1.56
                    var lx=cx+Math.cos(la)*(r+42), ly=cy+Math.sin(la)*(r+42)
                    ctx.fillText(labels[j],lx,ly+4)
                }
            }
        }

        Canvas {
            id: speedGaugeCanvas
            x:10; y:4; width:parent.width-20; height:280
            onPaint: {
                var ctx=getContext("2d")
                ctx.clearRect(0,0,width,height)
                var cx=width/2, cy=172, r=112
                var pct=Math.min(displaySpeed/3.0,1.0)
                if (pct <= 0.001) return
                var startA=Math.PI*0.72
                var endA=startA+pct*Math.PI*1.56
                var grad=ctx.createLinearGradient(0,0,width,0)
                grad.addColorStop(0,primary); grad.addColorStop(0.5,accent); grad.addColorStop(1.0,warningColor)
                ctx.beginPath(); ctx.arc(cx,cy,r,startA,endA)
                ctx.strokeStyle=grad; ctx.lineWidth=18; ctx.lineCap="round"; ctx.stroke()
                var na=endA
                ctx.shadowColor="#ffffff"; ctx.shadowBlur=8
                ctx.beginPath(); ctx.arc(cx+Math.cos(na)*r,cy+Math.sin(na)*r,7,0,Math.PI*2)
                ctx.fillStyle="#ffffff"; ctx.fill(); ctx.shadowBlur=0
            }
        }

        // Speed number
        Text {
            anchors.horizontalCenter:parent.horizontalCenter; y:88
            text:(displaySpeed*3.6).toFixed(1)
            color:"white"; font.pixelSize:66; font.bold:true; font.family:"Courier New"
        }
        Text {
            anchors.horizontalCenter:parent.horizontalCenter; y:162
            text:"km/h"; color:primary; font.pixelSize:17; font.family:"Courier New"; font.letterSpacing:6
        }

        // RPM number — same size as km/h
        Text {
            anchors.horizontalCenter:parent.horizontalCenter; y:210
            text:displayRpm.toFixed(0)
            color:rpmColor; font.pixelSize:66; font.bold:true; font.family:"Courier New"
        }
        Text {
            anchors.horizontalCenter:parent.horizontalCenter; y:284
            text:"RPM"; color:rpmColor; font.pixelSize:17; font.family:"Courier New"; font.letterSpacing:6; opacity:0.7
        }

        // m/s small
        Text {
            anchors.horizontalCenter:parent.horizontalCenter; y:312
            text:displaySpeed.toFixed(3)+" m/s"
            color:Qt.rgba(1,1,1,0.2); font.pixelSize:14; font.family:"Courier New"
        }

        // Mini bars
        Row {
            anchors.horizontalCenter:parent.horizontalCenter; y:350; spacing:14

            Column {
                spacing:4
                Text { anchors.horizontalCenter:parent.horizontalCenter; text:"SPD"; color:Qt.rgba(1,1,1,0.25); font.pixelSize:9; font.family:"Courier New"; font.letterSpacing:2 }
                Rectangle { width:98; height:4; radius:2; color:Qt.rgba(1,1,1,0.08)
                    Rectangle { width:Math.min(displaySpeed/3.0,1.0)*98; height:4; radius:2; color:primary }
                }
            }
            Column {
                spacing:4
                Text { anchors.horizontalCenter:parent.horizontalCenter; text:"RPM"; color:Qt.rgba(1,1,1,0.25); font.pixelSize:9; font.family:"Courier New"; font.letterSpacing:2 }
                Rectangle { width:98; height:4; radius:2; color:Qt.rgba(1,1,1,0.08)
                    Rectangle { width:Math.min(displayRpm/3000.0,1.0)*98; height:4; radius:2; color:rpmColor }
                }
            }
        }
    }

    
    Item {
        x: parent.width-256; y:52; width:246; height:400

        Column {
            x:14; y:8; spacing:14

            // Speed card
            Rectangle {
                width:218; height:72; radius:12
                color:Qt.rgba(1,1,1,0.04); border.color:primaryBorder; border.width:1
                Row {
                    x:16; anchors.verticalCenter:parent.verticalCenter; spacing:14
                    Canvas {
                        id: speedCardIcon
                        width:32; height:32; anchors.verticalCenter:parent.verticalCenter
                        onPaint: {
                            var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                            ctx.strokeStyle=speedColor; ctx.lineWidth=2
                            ctx.beginPath(); ctx.arc(16,20,12,Math.PI*0.8,Math.PI*0.2); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(16,20); ctx.lineTo(23,12); ctx.stroke()
                            ctx.beginPath(); ctx.arc(16,20,2,0,Math.PI*2)
                            ctx.fillStyle=speedColor; ctx.fill()
                        }
                    }
                    Column {
                        spacing:2; anchors.verticalCenter:parent.verticalCenter
                        Text { text:(displaySpeed*3.6).toFixed(2); color:speedColor; font.pixelSize:26; font.bold:true; font.family:"Courier New" }
                        Text { text:"km/h  Speed"; color:Qt.rgba(1,1,1,0.3); font.pixelSize:10; font.family:"Courier New" }
                    }
                }
            }

            // RPM card
            Rectangle {
                width:218; height:72; radius:12
                color:Qt.rgba(1,1,1,0.04); border.color:rpmBorder; border.width:1
                Row {
                    x:16; anchors.verticalCenter:parent.verticalCenter; spacing:14
                    Canvas {
                        id: rpmCardIcon
                        width:32; height:32; anchors.verticalCenter:parent.verticalCenter
                        onPaint: {
                            var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                            ctx.strokeStyle=rpmColor; ctx.lineWidth=2; ctx.lineCap="round"
                            ctx.beginPath(); ctx.arc(16,16,12,Math.PI*0.75,Math.PI*2.25); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(16,16); ctx.lineTo(24,10)
                            ctx.strokeStyle=rpmColor; ctx.lineWidth=2; ctx.stroke()
                        }
                    }
                    Column {
                        spacing:2; anchors.verticalCenter:parent.verticalCenter
                        Text { text:displayRpm.toFixed(0); color:rpmColor; font.pixelSize:26; font.bold:true; font.family:"Courier New" }
                        Text { text:"RPM"; color:Qt.rgba(1,1,1,0.3); font.pixelSize:10; font.family:"Courier New" }
                    }
                }
            }

            // Temp card
            Rectangle {
                width:218; height:72; radius:12
                color:Qt.rgba(1,1,1,0.04); border.color:tempBorder; border.width:1
                Row {
                    x:16; anchors.verticalCenter:parent.verticalCenter; spacing:14
                    Canvas {
                        id: tempCardIcon
                        width:32; height:40; anchors.verticalCenter:parent.verticalCenter
                        onPaint: {
                            var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                            var pct=Math.min(Math.max((vehicle.temperature-20)/60,0),1)
                            var bars=Math.ceil(pct*4)
                            for(var i=0;i<4;i++){
                                var bh=8+i*7; var bx=i*8+2
                                ctx.fillStyle=i<bars?tempColor:"rgba(255,255,255,0.1)"
                                ctx.fillRect(bx,36-bh,6,bh)
                            }
                        }
                        property real tmp:vehicle.temperature; onTmpChanged:requestPaint()
                    }
                    Column {
                        spacing:2; anchors.verticalCenter:parent.verticalCenter
                        Text { text:vehicle.temperature.toFixed(1)+"°C"; color:tempColor; font.pixelSize:26; font.bold:true; font.family:"Courier New" }
                        Text { text:"Engine Temp"; color:Qt.rgba(1,1,1,0.3); font.pixelSize:10; font.family:"Courier New" }
                    }
                }
            }

            // Battery card
            Rectangle {
                width:218; height:72; radius:12
                color:Qt.rgba(1,1,1,0.04)
                border.color: batteryLevel>50?accentBorder:batteryLevel>20?warningBorder:Qt.rgba(1,0.2,0.2,0.3)
                border.width:1
                Row {
                    x:16; anchors.verticalCenter:parent.verticalCenter; spacing:14
                    Canvas {
                        id: batteryCardIcon
                        width:42; height:22; anchors.verticalCenter:parent.verticalCenter
                        onPaint: {
                            var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                            var clr=batteryLevel>50?accent:batteryLevel>20?warningColor:dangerColor
                            ctx.strokeStyle=clr; ctx.lineWidth=2
                            ctx.strokeRect(1,1,34,20)
                            ctx.strokeRect(35,6,4,10)
                            var fw=(batteryLevel/100)*30
                            ctx.fillStyle=clr
                            ctx.fillRect(3,3,fw,16)
                        }
                        property real batt:batteryLevel; onBattChanged:requestPaint()
                    }
                    Column {
                        spacing:2; anchors.verticalCenter:parent.verticalCenter
                        Text {
                            text:batteryLevel.toFixed(0)+"%"
                            color:batteryLevel>50?accent:batteryLevel>20?warningColor:dangerColor
                            font.pixelSize:26; font.bold:true; font.family:"Courier New"
                        }
                        Text { text:"Battery"; color:Qt.rgba(1,1,1,0.3); font.pixelSize:10; font.family:"Courier New" }
                    }
                }
            }

            // Temp+RPM mini bars
            Column {
                x:0; spacing:8; width:218

                Row { spacing:8
                    Text { width:30; text:"TMP"; color:Qt.rgba(1,1,1,0.25); font.pixelSize:9; font.family:"Courier New"; anchors.verticalCenter:parent.verticalCenter }
                    Rectangle { width:180; height:3; radius:2; color:Qt.rgba(1,1,1,0.08); anchors.verticalCenter:parent.verticalCenter
                        Rectangle { width:Math.min(Math.max((vehicle.temperature-20)/60,0),1)*180; height:3; radius:2; color:tempColor; Behavior on width{NumberAnimation{duration:120}} }
                    }
                }
                Row { spacing:8
                    Text { width:30; text:"BAT"; color:Qt.rgba(1,1,1,0.25); font.pixelSize:9; font.family:"Courier New"; anchors.verticalCenter:parent.verticalCenter }
                    Rectangle { width:180; height:3; radius:2; color:Qt.rgba(1,1,1,0.08); anchors.verticalCenter:parent.verticalCenter
                        Rectangle { width:(batteryLevel/100)*180; height:3; radius:2; color:accent; Behavior on width{NumberAnimation{duration:120}} }
                    }
                }
            }
        }
    }

    }

    Rectangle {
        anchors.fill: parent
        z: 500
        visible: themeReloading && !introActive
        color: "black"
    }

    MediaPlayer {
        id: introPlayer
        source: "qrc:/DATN_dashboard_car/assets/intro.mp4"
        videoOutput: introOutput
        audioOutput: AudioOutput { muted: true }
        Component.onCompleted: play()
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) finishIntro()
        }
        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.StoppedState) finishIntro()
        }
        onErrorOccurred: finishIntro()
    }

    VideoOutput {
        id: introOutput
        anchors.fill: parent
        visible: introActive
        opacity: introActive ? 1.0 : 0.0
        fillMode: VideoOutput.PreserveAspectCrop
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Timer {
        interval: 9000
        running: introActive
        repeat: false
        onTriggered: finishIntro()
    }

    Rectangle {
        anchors.fill: parent
        visible: introActive && introPlayer.playbackState !== MediaPlayer.PlayingState
        color: "black"
    }

}

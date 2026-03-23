import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    visible: true
    width: 1024
    height: 480
    color: "#080c12"
    title: "DATN Dashboard"

    property bool leftSignal:  false
    property bool rightSignal: false
    property bool headLight:   false
    property int  signalTick:  0
    property real batteryLevel: 85.0

    Timer {
        interval: 500
        running: leftSignal || rightSignal
        repeat: true
        onTriggered: signalTick = (signalTick + 1) % 2
    }

    // Outer border
    Rectangle {
        anchors.fill: parent; color: "transparent"
        border.color: "#00e5cc"; border.width: 3; radius: 28; z: 100
    }

    // Top bar
    Rectangle {
        x: 3; y: 3; width: parent.width-6; height: 40
        color: "#00e5cc"; radius: 25
        Rectangle { x:0; y:20; width: parent.width; height:20; color:"#00e5cc" }
        Row {
            anchors.centerIn: parent; spacing: 40
            Text {
                text: Qt.formatTime(new Date(), "hh:mm")
                color: "#080c12"; font.pixelSize:16; font.bold:true; font.family:"Courier New"
                Timer { interval:1000; running:true; repeat:true; onTriggered: parent.text = Qt.formatTime(new Date(),"hh:mm") }
            }
            Text {
                text: Qt.formatDate(new Date(), "dd/MM/yyyy")
                color: "#080c12"; font.pixelSize:14; font.family:"Courier New"
            }
        }
    }

    // Separators
    Rectangle { x:256; y:52; width:1; height:390; color: Qt.rgba(0,0.9,0.8,0.12) }
    Rectangle { x:parent.width-257; y:52; width:1; height:390; color: Qt.rgba(0,0.9,0.8,0.12) }

   
    Item {
        x: 10; y: 52; width: 246; height: 400

        // Battery arc
        Canvas {
            x: 23; y: 8; width: 200; height: 200
            onPaint: {
                var ctx = getContext("2d")
                var cx=100, cy=100, r=80
                ctx.beginPath(); ctx.arc(cx,cy,r,-Math.PI*0.8,Math.PI*0.8)
                ctx.strokeStyle="rgba(255,255,255,0.07)"; ctx.lineWidth=12; ctx.lineCap="round"; ctx.stroke()
                var pct = batteryLevel/100.0
                var grad = ctx.createLinearGradient(0,0,200,0)
                if(batteryLevel>50){ grad.addColorStop(0,"#00e5cc"); grad.addColorStop(1,"#00ff88") }
                else if(batteryLevel>20){ grad.addColorStop(0,"#ffcc00"); grad.addColorStop(1,"#ff8800") }
                else { grad.addColorStop(0,"#ff4444"); grad.addColorStop(1,"#ff0000") }
                ctx.beginPath(); ctx.arc(cx,cy,r,-Math.PI*0.8,-Math.PI*0.8+pct*Math.PI*1.6)
                ctx.strokeStyle=grad; ctx.lineWidth=12; ctx.lineCap="round"; ctx.stroke()
            }
            property real batt: batteryLevel
            onBattChanged: requestPaint()
        }
        Text {
            x:23; y:80; width:200
            text: batteryLevel.toFixed(0)+"%"
            color: batteryLevel>50?"#00e5cc":batteryLevel>20?"#ffcc00":"#ff4444"
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
                width:36; height:36
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                    ctx.fillStyle=(leftSignal&&signalTick===0)?"#00ff44":"rgba(255,255,255,0.1)"
                    ctx.beginPath(); ctx.moveTo(36,6); ctx.lineTo(16,18); ctx.lineTo(36,30); ctx.closePath(); ctx.fill()
                    ctx.beginPath(); ctx.moveTo(20,6); ctx.lineTo(0,18);  ctx.lineTo(20,30); ctx.closePath(); ctx.fill()
                }
                property bool ls:leftSignal; property int st:signalTick
                onLsChanged: requestPaint(); onStChanged: requestPaint()
                MouseArea { anchors.fill:parent; onClicked:{ leftSignal=!leftSignal; if(leftSignal)rightSignal=false } }
            }
            Canvas {
                width:36; height:36
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                    ctx.fillStyle=(leftSignal&&rightSignal)?"#ffcc00":"rgba(255,255,255,0.1)"
                    ctx.beginPath(); ctx.moveTo(18,2); ctx.lineTo(34,32); ctx.lineTo(2,32); ctx.closePath(); ctx.fill()
                }
                property bool ls:leftSignal; property bool rs:rightSignal
                onLsChanged: requestPaint(); onRsChanged: requestPaint()
                MouseArea { anchors.fill:parent; onClicked:{ leftSignal=!leftSignal; rightSignal=leftSignal } }
            }
            Canvas {
                width:36; height:36
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                    ctx.fillStyle=(rightSignal&&signalTick===0)?"#00ff44":"rgba(255,255,255,0.1)"
                    ctx.beginPath(); ctx.moveTo(0,6);  ctx.lineTo(20,18); ctx.lineTo(0,30);  ctx.closePath(); ctx.fill()
                    ctx.beginPath(); ctx.moveTo(14,6); ctx.lineTo(34,18); ctx.lineTo(14,30); ctx.closePath(); ctx.fill()
                }
                property bool rs:rightSignal; property int st:signalTick
                onRsChanged: requestPaint(); onStChanged: requestPaint()
                MouseArea { anchors.fill:parent; onClicked:{ rightSignal=!rightSignal; if(rightSignal)leftSignal=false } }
            }
            Canvas {
                width:36; height:36
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                    ctx.strokeStyle=headLight?"#ffee44":"rgba(255,255,255,0.15)"
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
                MouseArea { anchors.fill:parent; onClicked:headLight=!headLight }
            }
            Canvas {
                width:36; height:36
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                    // Thermometer icon
                    ctx.strokeStyle="#ffaa00"; ctx.lineWidth=2
                    ctx.beginPath(); ctx.moveTo(14,4); ctx.lineTo(14,26); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(22,4); ctx.lineTo(22,26); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(14,4); ctx.arc(18,4,4,-Math.PI,0); ctx.stroke()
                    ctx.beginPath(); ctx.arc(18,30,6,0,Math.PI*2)
                    ctx.fillStyle="#ffaa00"; ctx.fill()
                    // fill
                    var pct=Math.min(Math.max((vehicle.temperature-20)/60,0),1)
                    ctx.fillStyle="#ffaa00"
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

        // BLE pill
        Rectangle {
            x:14; y:294; width:218; height:32; radius:16
            color: vehicle.bleConnected ? Qt.rgba(0,0.9,0.5,0.1) : Qt.rgba(1,0.2,0.2,0.1)
            border.color: vehicle.bleConnected?"#00e5cc":"#ff4444"; border.width:1
            Row {
                anchors.centerIn:parent; spacing:8
                Rectangle {
                    width:8; height:8; radius:4
                    anchors.verticalCenter:parent.verticalCenter
                    color:vehicle.bleConnected?"#00e5cc":"#ff4444"
                    SequentialAnimation on opacity {
                        running:!vehicle.bleConnected; loops:Animation.Infinite
                        NumberAnimation{to:0.2;duration:700} NumberAnimation{to:1.0;duration:700}
                    }
                }
                Text {
                    anchors.verticalCenter:parent.verticalCenter
                    text:vehicle.bleConnected?"BLE CONNECTED":"BLE SCANNING..."
                    color:vehicle.bleConnected?"#00e5cc":"#ff4444"
                    font.pixelSize:11; font.family:"Courier New"; font.letterSpacing:1
                }
            }
        }

        // Temp value
        Row {
            x:14; y:338; spacing:10
            Canvas {
                width:28; height:40
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                    // signal bars
                    var pct=Math.min(Math.max((vehicle.temperature-20)/60,0),1)
                    var bars=Math.ceil(pct*4)
                    for(var i=0;i<4;i++){
                        var bh=6+i*6; var bx=i*7
                        ctx.fillStyle=i<bars?"#ffaa00":"rgba(255,255,255,0.1)"
                        ctx.fillRect(bx,34-bh,5,bh)
                    }
                }
                property real tmp:vehicle.temperature; onTmpChanged:requestPaint()
            }
            Column {
                spacing:2
                Text { text:vehicle.temperature.toFixed(1)+"°C"; color:"#ffaa00"; font.pixelSize:22; font.bold:true; font.family:"Courier New" }
                Text { text:"Engine Temp"; color:Qt.rgba(1,1,1,0.3); font.pixelSize:10; font.family:"Courier New" }
            }
        }
    }

    
    Item {
        x: 256; y: 48
        width: parent.width - 512; height: 432

        
        Canvas {
            x:10; y:4; width:parent.width-20; height:280
            onPaint: {
                var ctx=getContext("2d")
                var cx=width/2, cy=200, r=150
                ctx.beginPath(); ctx.arc(cx,cy,r,Math.PI*0.72,Math.PI*2.28)
                ctx.strokeStyle="rgba(255,255,255,0.06)"; ctx.lineWidth=18; ctx.lineCap="round"; ctx.stroke()
                var pct=Math.min(vehicle.speed/3.0,1.0)
                var startA=Math.PI*0.72; var endA=startA+pct*Math.PI*1.56
                var grad=ctx.createLinearGradient(0,0,width,0)
                grad.addColorStop(0,"#00e5cc"); grad.addColorStop(0.5,"#00ff88"); grad.addColorStop(1.0,"#ffcc00")
                ctx.beginPath(); ctx.arc(cx,cy,r,startA,endA)
                ctx.strokeStyle=grad; ctx.lineWidth=18; ctx.lineCap="round"; ctx.stroke()
                // Needle
                var na=startA+pct*Math.PI*1.56
                ctx.shadowColor="#ffffff"; ctx.shadowBlur=15
                ctx.beginPath(); ctx.arc(cx+Math.cos(na)*r,cy+Math.sin(na)*r,8,0,Math.PI*2)
                ctx.fillStyle="#ffffff"; ctx.fill(); ctx.shadowBlur=0
                // Ticks
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
                // Tick labels
                ctx.fillStyle="rgba(255,255,255,0.4)"; ctx.font="12px Courier New"
                ctx.textAlign="center"
                var labels=["0","","","1","","","2","","","3","","",""]
                for(var j=0;j<=12;j++){
                    var la=startA+(j/12)*Math.PI*1.56
                    var lx=cx+Math.cos(la)*(r+42), ly=cy+Math.sin(la)*(r+42)
                    ctx.fillText(labels[j],lx,ly+4)
                }
            }
            property real spdVal:vehicle.speed; onSpdValChanged:requestPaint()
        }

        // Speed number
        Text {
            anchors.horizontalCenter:parent.horizontalCenter; y:90
            text:(vehicle.speed*3.6).toFixed(1)
            color:"white"; font.pixelSize:90; font.bold:true; font.family:"Courier New"
        }
        Text {
            anchors.horizontalCenter:parent.horizontalCenter; y:188
            text:"km/h"; color:"#00e5cc"; font.pixelSize:20; font.family:"Courier New"; font.letterSpacing:8
        }

        // RPM number — same size as km/h
        Text {
            anchors.horizontalCenter:parent.horizontalCenter; y:218
            text:vehicle.rpm.toFixed(0)
            color:"#9966ff"; font.pixelSize:90; font.bold:true; font.family:"Courier New"
        }
        Text {
            anchors.horizontalCenter:parent.horizontalCenter; y:316
            text:"RPM"; color:"#9966ff"; font.pixelSize:20; font.family:"Courier New"; font.letterSpacing:8; opacity:0.7
        }

        // m/s small
        Text {
            anchors.horizontalCenter:parent.horizontalCenter; y:342
            text:vehicle.speed.toFixed(3)+" m/s"
            color:Qt.rgba(1,1,1,0.2); font.pixelSize:14; font.family:"Courier New"
        }

        // Mini bars
        Row {
            anchors.horizontalCenter:parent.horizontalCenter; y:368; spacing:24

            Column {
                spacing:4
                Text { anchors.horizontalCenter:parent.horizontalCenter; text:"SPD"; color:Qt.rgba(1,1,1,0.25); font.pixelSize:9; font.family:"Courier New"; font.letterSpacing:2 }
                Rectangle { width:120; height:4; radius:2; color:Qt.rgba(1,1,1,0.08)
                    Rectangle { width:Math.min(vehicle.speed/3.0,1.0)*120; height:4; radius:2; color:"#00e5cc"; Behavior on width{NumberAnimation{duration:200}} }
                }
            }
            Column {
                spacing:4
                Text { anchors.horizontalCenter:parent.horizontalCenter; text:"RPM"; color:Qt.rgba(1,1,1,0.25); font.pixelSize:9; font.family:"Courier New"; font.letterSpacing:2 }
                Rectangle { width:120; height:4; radius:2; color:Qt.rgba(1,1,1,0.08)
                    Rectangle { width:Math.min(vehicle.rpm/3000.0,1.0)*120; height:4; radius:2; color:"#9966ff"; Behavior on width{NumberAnimation{duration:200}} }
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
                color:Qt.rgba(1,1,1,0.04); border.color:Qt.rgba(0,0.9,0.8,0.15); border.width:1
                Row {
                    x:16; anchors.verticalCenter:parent.verticalCenter; spacing:14
                    Canvas {
                        width:32; height:32; anchors.verticalCenter:parent.verticalCenter
                        onPaint: {
                            var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                            ctx.strokeStyle="#00d4ff"; ctx.lineWidth=2
                            ctx.beginPath(); ctx.arc(16,20,12,Math.PI*0.8,Math.PI*0.2); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(16,20); ctx.lineTo(23,12); ctx.stroke()
                            ctx.beginPath(); ctx.arc(16,20,2,0,Math.PI*2)
                            ctx.fillStyle="#00d4ff"; ctx.fill()
                        }
                    }
                    Column {
                        spacing:2; anchors.verticalCenter:parent.verticalCenter
                        Text { text:(vehicle.speed*3.6).toFixed(2); color:"#00d4ff"; font.pixelSize:26; font.bold:true; font.family:"Courier New" }
                        Text { text:"km/h  Speed"; color:Qt.rgba(1,1,1,0.3); font.pixelSize:10; font.family:"Courier New" }
                    }
                }
            }

            // RPM card
            Rectangle {
                width:218; height:72; radius:12
                color:Qt.rgba(1,1,1,0.04); border.color:Qt.rgba(0.6,0.4,1,0.2); border.width:1
                Row {
                    x:16; anchors.verticalCenter:parent.verticalCenter; spacing:14
                    Canvas {
                        width:32; height:32; anchors.verticalCenter:parent.verticalCenter
                        onPaint: {
                            var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                            ctx.strokeStyle="#9966ff"; ctx.lineWidth=2; ctx.lineCap="round"
                            ctx.beginPath(); ctx.arc(16,16,12,Math.PI*0.75,Math.PI*2.25); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(16,16); ctx.lineTo(24,10)
                            ctx.strokeStyle="#9966ff"; ctx.lineWidth=2; ctx.stroke()
                        }
                    }
                    Column {
                        spacing:2; anchors.verticalCenter:parent.verticalCenter
                        Text { text:vehicle.rpm.toFixed(0); color:"#9966ff"; font.pixelSize:26; font.bold:true; font.family:"Courier New" }
                        Text { text:"RPM"; color:Qt.rgba(1,1,1,0.3); font.pixelSize:10; font.family:"Courier New" }
                    }
                }
            }

            // Temp card
            Rectangle {
                width:218; height:72; radius:12
                color:Qt.rgba(1,1,1,0.04); border.color:Qt.rgba(1,0.67,0,0.2); border.width:1
                Row {
                    x:16; anchors.verticalCenter:parent.verticalCenter; spacing:14
                    Canvas {
                        width:32; height:40; anchors.verticalCenter:parent.verticalCenter
                        onPaint: {
                            var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                            var pct=Math.min(Math.max((vehicle.temperature-20)/60,0),1)
                            var bars=Math.ceil(pct*4)
                            for(var i=0;i<4;i++){
                                var bh=8+i*7; var bx=i*8+2
                                ctx.fillStyle=i<bars?"#ffaa00":"rgba(255,255,255,0.1)"
                                ctx.fillRect(bx,36-bh,6,bh)
                            }
                        }
                        property real tmp:vehicle.temperature; onTmpChanged:requestPaint()
                    }
                    Column {
                        spacing:2; anchors.verticalCenter:parent.verticalCenter
                        Text { text:vehicle.temperature.toFixed(1)+"°C"; color:"#ffaa00"; font.pixelSize:26; font.bold:true; font.family:"Courier New" }
                        Text { text:"Engine Temp"; color:Qt.rgba(1,1,1,0.3); font.pixelSize:10; font.family:"Courier New" }
                    }
                }
            }

            // Battery card
            Rectangle {
                width:218; height:72; radius:12
                color:Qt.rgba(1,1,1,0.04)
                border.color: batteryLevel>50?Qt.rgba(0,1,0.5,0.2):batteryLevel>20?Qt.rgba(1,0.8,0,0.2):Qt.rgba(1,0.2,0.2,0.3)
                border.width:1
                Row {
                    x:16; anchors.verticalCenter:parent.verticalCenter; spacing:14
                    Canvas {
                        width:42; height:22; anchors.verticalCenter:parent.verticalCenter
                        onPaint: {
                            var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
                            var clr=batteryLevel>50?"#00ff88":batteryLevel>20?"#ffcc00":"#ff4444"
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
                            color:batteryLevel>50?"#00ff88":batteryLevel>20?"#ffcc00":"#ff4444"
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
                        Rectangle { width:Math.min(Math.max((vehicle.temperature-20)/60,0),1)*180; height:3; radius:2; color:"#ffaa00"; Behavior on width{NumberAnimation{duration:500}} }
                    }
                }
                Row { spacing:8
                    Text { width:30; text:"BAT"; color:Qt.rgba(1,1,1,0.25); font.pixelSize:9; font.family:"Courier New"; anchors.verticalCenter:parent.verticalCenter }
                    Rectangle { width:180; height:3; radius:2; color:Qt.rgba(1,1,1,0.08); anchors.verticalCenter:parent.verticalCenter
                        Rectangle { width:(batteryLevel/100)*180; height:3; radius:2; color:"#00ff88"; Behavior on width{NumberAnimation{duration:500}} }
                    }
                }
            }
        }
    }

    // Bottom bar
    Rectangle {
        x:3; y:parent.height-36; width:parent.width-6; height:33; radius:0
        color:Qt.rgba(0,0.9,0.8,0.05)
        Rectangle { x:0; y:0; width:parent.width; height:1; color:Qt.rgba(0,0.9,0.8,0.18) }
        Text {
            anchors.centerIn:parent
            text:"DATN DASHBOARD  ·  RPi4  ·  Qt 6.5"
            color:Qt.rgba(1,1,1,0.15); font.pixelSize:11; font.family:"Courier New"; font.letterSpacing:3
        }
    }
}

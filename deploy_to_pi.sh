#!/bin/bash
set -e

PI_IP="192.168.12.204"
PI_USER="pi"
PI_PASS="123456"
LOCAL_BIN="/home/quanghaictu/build-DATN_dashboard_car-RPI-Debug/appDATN_dashboard_car"
REMOTE_BIN="/usr/local/bin/appDATN_dashboard_car"

echo "Checking connection to $PI_IP..."
if ! ping -c 1 -W 2 "$PI_IP" >/dev/null 2>&1; then
    echo "ERROR: Cannot ping $PI_IP. Please check if Raspberry Pi is powered on and connected to hotspot 'Iot'."
    exit 1
fi

echo "Stopping running instance on Pi and resetting BLE..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
    "pkill -9 -f '\[a\]ppDATN_dashboa' 2>/dev/null || true; sudo hciconfig hci0 reset 2>/dev/null; sudo hciconfig hci0 up 2>/dev/null || true"

echo "Copying binary to Pi..."
sshpass -p "$PI_PASS" scp -o StrictHostKeyChecking=no "$LOCAL_BIN" "$PI_USER@$PI_IP:/home/pi/appDATN_dashboard_car.tmp"

echo "Installing binary to $REMOTE_BIN..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
    "echo $PI_PASS | sudo -S mv -f /home/pi/appDATN_dashboard_car.tmp $REMOTE_BIN && echo $PI_PASS | sudo -S chmod +x $REMOTE_BIN"

echo "Starting application on display :0..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
    "bash -c 'DISPLAY=:0 XAUTHORITY=/home/pi/.Xauthority nohup $REMOTE_BIN > /tmp/app.log 2>&1 &'"

sleep 2
echo "Checking app log on Pi..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "cat /tmp/app.log"
echo "Deployment successful!"

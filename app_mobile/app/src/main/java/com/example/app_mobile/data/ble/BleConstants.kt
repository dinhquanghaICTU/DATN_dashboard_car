package com.example.app_mobile.data.ble

import java.util.UUID

object BleConstants {
    const val TARGET_DEVICE_NAME = "DATN-Car"

    val SERVICE_UUID: UUID = UUID.fromString("12345678-1234-1234-1234-123456789abc")
    val CHARACTERISTIC_UUID: UUID = UUID.fromString("12345678-1234-1234-1234-123456789abd")

    const val SCAN_PERIOD_MS = 10000L
    const val RECONNECT_DELAY_MS = 3000L
    const val DEFAULT_SPEED = 70
}

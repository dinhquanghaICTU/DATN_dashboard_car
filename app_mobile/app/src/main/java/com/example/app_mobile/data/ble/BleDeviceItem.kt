package com.example.app_mobile.data.ble

data class BleDeviceItem(
    val name: String,
    val address: String,
    val rssi: Int = 0,
    val isTarget: Boolean = false
)

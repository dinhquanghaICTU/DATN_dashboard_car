package com.example.app_mobile.data.ble

sealed class BleConnectionState {
    object Disconnected : BleConnectionState()
    object Scanning : BleConnectionState()
    data class Connecting(val deviceName: String, val address: String) : BleConnectionState()
    data class Connected(val deviceName: String, val address: String) : BleConnectionState()
    data class Error(val message: String) : BleConnectionState()
}

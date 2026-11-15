package com.example.app_mobile.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.example.app_mobile.data.ble.BleConnectionState
import com.example.app_mobile.data.ble.BleConstants
import com.example.app_mobile.data.ble.BleDeviceItem
import com.example.app_mobile.data.ble.BleManager
import com.example.app_mobile.data.model.CarCommand
import com.example.app_mobile.data.model.DriveDirection
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class CarViewModel(private val bleManager: BleManager) : ViewModel() {

    val connectionState: StateFlow<BleConnectionState> = bleManager.connectionState
    val scannedDevices: StateFlow<List<BleDeviceItem>> = bleManager.scannedDevices
    val lastSentCommand: StateFlow<String> = bleManager.lastSentCommand

    private val _currentSpeed = MutableStateFlow(BleConstants.DEFAULT_SPEED)
    val currentSpeed: StateFlow<Int> = _currentSpeed.asStateFlow()

    private val _activeDirection = MutableStateFlow<DriveDirection?>(null)
    val activeDirection: StateFlow<DriveDirection?> = _activeDirection.asStateFlow()

    private val _headlightActive = MutableStateFlow(false)
    val headlightActive: StateFlow<Boolean> = _headlightActive.asStateFlow()

    private val _leftSignalActive = MutableStateFlow(false)
    val leftSignalActive: StateFlow<Boolean> = _leftSignalActive.asStateFlow()

    private val _rightSignalActive = MutableStateFlow(false)
    val rightSignalActive: StateFlow<Boolean> = _rightSignalActive.asStateFlow()

    private val _hazardActive = MutableStateFlow(false)
    val hazardActive: StateFlow<Boolean> = _hazardActive.asStateFlow()

    private val _showScanDialog = MutableStateFlow(false)
    val showScanDialog: StateFlow<Boolean> = _showScanDialog.asStateFlow()

    fun setShowScanDialog(show: Boolean) {
        _showScanDialog.value = show
        if (show) {
            startScan()
        } else {
            stopScan()
        }
    }

    fun startScan() {
        bleManager.startScan()
    }

    fun stopScan() {
        bleManager.stopScan()
    }

    fun connectDevice(address: String) {
        bleManager.connect(address)
        _showScanDialog.value = false
    }

    fun disconnect() {
        bleManager.disconnect()
    }

    fun setSpeed(speed: Int) {
        _currentSpeed.value = speed.coerceIn(30, 100)
    }

    fun onDirectionPress(direction: DriveDirection) {
        _activeDirection.value = direction
        val speed = _currentSpeed.value
        val cmd = when (direction) {
            DriveDirection.FORWARD -> CarCommand.Forward(speed)
            DriveDirection.BACKWARD -> CarCommand.Backward(speed)
            DriveDirection.LEFT -> CarCommand.TurnLeft(speed)
            DriveDirection.RIGHT -> CarCommand.TurnRight(speed)
        }
        bleManager.sendCommand(cmd.rawValue)
    }

    fun onDirectionRelease() {
        _activeDirection.value = null
        bleManager.sendCommand(CarCommand.Stop.rawValue)
    }

    fun emergencyStop() {
        _activeDirection.value = null
        bleManager.sendCommand(CarCommand.Stop.rawValue)
    }

    fun toggleHeadlight() {
        _headlightActive.value = !_headlightActive.value
        bleManager.sendCommand(CarCommand.ToggleHeadlight.rawValue)
    }

    fun toggleLeftSignal() {
        val newState = !_leftSignalActive.value
        _leftSignalActive.value = newState
        if (newState) _rightSignalActive.value = false
        bleManager.sendCommand(CarCommand.ToggleLeftSignal.rawValue)
    }

    fun toggleRightSignal() {
        val newState = !_rightSignalActive.value
        _rightSignalActive.value = newState
        if (newState) _leftSignalActive.value = false
        bleManager.sendCommand(CarCommand.ToggleRightSignal.rawValue)
    }

    fun toggleHazard() {
        val newState = !_hazardActive.value
        _hazardActive.value = newState
        if (newState) {
            _leftSignalActive.value = false
            _rightSignalActive.value = false
        }
        bleManager.sendCommand(CarCommand.ToggleHazard.rawValue)
    }

    override fun onCleared() {
        super.onCleared()
        bleManager.close()
    }
}

class CarViewModelFactory(private val bleManager: BleManager) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(CarViewModel::class.java)) {
            return CarViewModel(bleManager) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}

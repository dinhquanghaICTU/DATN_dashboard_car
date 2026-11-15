package com.example.app_mobile.data.ble

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.bluetooth.BluetoothStatusCodes
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.nio.charset.StandardCharsets

class BleManager(private val context: Context) {

    companion object {
        private const val TAG = "BleManager"
    }

    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? get() = bluetoothManager?.adapter

    private var bluetoothGatt: BluetoothGatt? = null
    private var writeCharacteristic: BluetoothGattCharacteristic? = null

    private val handler = Handler(Looper.getMainLooper())
    private var isScanningInternal = false

    private val _connectionState = MutableStateFlow<BleConnectionState>(BleConnectionState.Disconnected)
    val connectionState: StateFlow<BleConnectionState> = _connectionState.asStateFlow()

    private val _scannedDevices = MutableStateFlow<List<BleDeviceItem>>(emptyList())
    val scannedDevices: StateFlow<List<BleDeviceItem>> = _scannedDevices.asStateFlow()

    private val _lastSentCommand = MutableStateFlow("")
    val lastSentCommand: StateFlow<String> = _lastSentCommand.asStateFlow()

    val isBluetoothEnabled: Boolean
        get() = bluetoothAdapter?.isEnabled == true

    private val scanCallback = object : ScanCallback() {
        @SuppressLint("MissingPermission")
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device ?: return
            val name = device.name ?: result.scanRecord?.deviceName ?: "Thiết bị không tên"
            val address = device.address ?: return
            val rssi = result.rssi
            val isTarget = name.equals(BleConstants.TARGET_DEVICE_NAME, ignoreCase = true)

            val currentList = _scannedDevices.value.toMutableList()
            val existingIndex = currentList.indexOfFirst { it.address == address }

            val item = BleDeviceItem(
                name = name,
                address = address,
                rssi = rssi,
                isTarget = isTarget
            )

            if (existingIndex >= 0) {
                currentList[existingIndex] = item
            } else {
                currentList.add(item)
            }

            // Đưa thiết bị DATN-Car lên đầu danh sách
            currentList.sortWith(compareByDescending<BleDeviceItem> { it.isTarget }.thenByDescending { it.rssi })
            _scannedDevices.value = currentList

            // Tự động kết nối nếu tìm thấy xe DATN-Car khi chưa kết nối
            if (isTarget && _connectionState.value is BleConnectionState.Scanning) {
                Log.d(TAG, "Tìm thấy DATN-Car tại $address! Tự động kết nối...")
                stopScan()
                connect(address)
            }
        }

        override fun onScanFailed(errorCode: Int) {
            Log.e(TAG, "Quét BLE thất bại mã: $errorCode")
            isScanningInternal = false
            _connectionState.value = BleConnectionState.Error("Quét BLE thất bại (Mã $errorCode)")
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            val deviceName = gatt.device?.name ?: BleConstants.TARGET_DEVICE_NAME
            val deviceAddress = gatt.device?.address ?: ""

            Log.d(TAG, "Trạng thái kết nối đổi: status=$status, newState=$newState")

            if (newState == BluetoothProfile.STATE_CONNECTED) {
                _connectionState.value = BleConnectionState.Connecting(deviceName, deviceAddress)
                Log.d(TAG, "Đã kết nối GATT, đang tìm kiếm Service...")
                handler.postDelayed({
                    gatt.discoverServices()
                }, 300)
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                Log.d(TAG, "Đã ngắt kết nối GATT")
                writeCharacteristic = null
                _connectionState.value = BleConnectionState.Disconnected
            }
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                val service = gatt.getService(BleConstants.SERVICE_UUID)
                if (service != null) {
                    val characteristic = service.getCharacteristic(BleConstants.CHARACTERISTIC_UUID)
                    if (characteristic != null) {
                        writeCharacteristic = characteristic
                        val deviceName = gatt.device?.name ?: BleConstants.TARGET_DEVICE_NAME
                        val deviceAddress = gatt.device?.address ?: ""
                        _connectionState.value = BleConnectionState.Connected(deviceName, deviceAddress)
                        Log.i(TAG, "Kết nối thành công Service & Characteristic của DATN-Car!")
                        return
                    }
                }
                Log.w(TAG, "Không tìm thấy Characteristic hoặc Service DATN mong muốn!")
                _connectionState.value = BleConnectionState.Error("Không tìm thấy cổng điều khiển của xe")
            } else {
                Log.e(TAG, "Lỗi tìm kiếm Services: $status")
                _connectionState.value = BleConnectionState.Error("Lỗi đọc dịch vụ BLE: $status")
            }
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int
        ) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(TAG, "Gửi lệnh thành công!")
            } else {
                Log.w(TAG, "Gửi lệnh thất bại với status=$status")
            }
        }
    }

    @SuppressLint("MissingPermission")
    fun startScan() {
        val scanner = bluetoothAdapter?.bluetoothLeScanner
        if (scanner == null) {
            _connectionState.value = BleConnectionState.Error("Không tìm thấy Bluetooth LE trên máy")
            return
        }

        _scannedDevices.value = emptyList()
        _connectionState.value = BleConnectionState.Scanning
        isScanningInternal = true

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        val filters = listOf(
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(BleConstants.SERVICE_UUID))
                .build(),
            ScanFilter.Builder()
                .setDeviceName(BleConstants.TARGET_DEVICE_NAME)
                .build()
        )

        try {
            // Quét với filter, nếu không thấy thì quét toàn bộ
            scanner.startScan(null, settings, scanCallback)
            handler.postDelayed({
                if (isScanningInternal) {
                    stopScan()
                }
            }, BleConstants.SCAN_PERIOD_MS)
        } catch (e: Exception) {
            Log.e(TAG, "Lỗi khi startScan", e)
            _connectionState.value = BleConnectionState.Error("Lỗi quét: ${e.localizedMessage}")
        }
    }

    @SuppressLint("MissingPermission")
    fun stopScan() {
        if (!isScanningInternal) return
        isScanningInternal = false
        try {
            bluetoothAdapter?.bluetoothLeScanner?.stopScan(scanCallback)
            if (_connectionState.value is BleConnectionState.Scanning) {
                _connectionState.value = BleConnectionState.Disconnected
            }
        } catch (e: Exception) {
            Log.e(TAG, "Lỗi khi stopScan", e)
        }
    }

    @SuppressLint("MissingPermission")
    fun connect(deviceAddress: String) {
        stopScan()
        disconnect()

        val device = bluetoothAdapter?.getRemoteDevice(deviceAddress)
        if (device == null) {
            _connectionState.value = BleConnectionState.Error("Không tìm thấy địa chỉ thiết bị: $deviceAddress")
            return
        }

        _connectionState.value = BleConnectionState.Connecting(
            device.name ?: BleConstants.TARGET_DEVICE_NAME,
            deviceAddress
        )

        try {
            bluetoothGatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                device.connectGatt(context, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
            } else {
                device.connectGatt(context, false, gattCallback)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Lỗi connectGatt", e)
            _connectionState.value = BleConnectionState.Error("Lỗi kết nối: ${e.localizedMessage}")
        }
    }

    @SuppressLint("MissingPermission")
    fun disconnect() {
        try {
            bluetoothGatt?.disconnect()
            bluetoothGatt?.close()
            bluetoothGatt = null
            writeCharacteristic = null
            _connectionState.value = BleConnectionState.Disconnected
        } catch (e: Exception) {
            Log.e(TAG, "Lỗi disconnect", e)
        }
    }

    @SuppressLint("MissingPermission")
    fun sendCommand(cmd: String): Boolean {
        val gatt = bluetoothGatt ?: return false
        val characteristic = writeCharacteristic ?: return false

        val bytes = cmd.toByteArray(StandardCharsets.UTF_8)
        _lastSentCommand.value = cmd

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val writeType = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                val res = gatt.writeCharacteristic(characteristic, bytes, writeType)
                res == BluetoothStatusCodes.SUCCESS
            } else {
                characteristic.value = bytes
                characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                gatt.writeCharacteristic(characteristic)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Lỗi gửi command '$cmd'", e)
            false
        }
    }

    fun close() {
        stopScan()
        disconnect()
    }
}

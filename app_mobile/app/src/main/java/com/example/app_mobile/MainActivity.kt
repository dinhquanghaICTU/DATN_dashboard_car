package com.example.app_mobile

import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.lifecycle.ViewModelProvider
import com.example.app_mobile.data.ble.BleManager
import com.example.app_mobile.ui.screens.CarDashboardScreen
import com.example.app_mobile.ui.theme.App_mobileTheme
import com.example.app_mobile.ui.viewmodel.CarViewModel
import com.example.app_mobile.ui.viewmodel.CarViewModelFactory
import com.example.app_mobile.util.BlePermissionManager

class MainActivity : ComponentActivity() {

    private lateinit var bleManager: BleManager
    private lateinit var viewModel: CarViewModel

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val allGranted = permissions.values.all { it }
        if (allGranted) {
            viewModel.startScan()
        } else {
            Toast.makeText(
                this,
                "Cần cấp đủ quyền Bluetooth để kết nối với xe DATN!",
                Toast.LENGTH_LONG
            ).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        bleManager = BleManager(applicationContext)
        val factory = CarViewModelFactory(bleManager)
        viewModel = ViewModelProvider(this, factory)[CarViewModel::class.java]

        checkAndRequestPermissions()

        setContent {
            App_mobileTheme {
                CarDashboardScreen(
                    viewModel = viewModel,
                    onRequestPermissions = { checkAndRequestPermissions() }
                )
            }
        }
    }

    private fun checkAndRequestPermissions() {
        if (!BlePermissionManager.hasRequiredPermissions(this)) {
            permissionLauncher.launch(BlePermissionManager.getRequiredPermissions())
        } else {
            viewModel.startScan()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        bleManager.close()
    }
}

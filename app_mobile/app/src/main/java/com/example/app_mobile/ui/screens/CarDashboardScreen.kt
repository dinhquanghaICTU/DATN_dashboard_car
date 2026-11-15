package com.example.app_mobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.app_mobile.data.ble.BleConnectionState
import com.example.app_mobile.ui.components.ConnectionStatusCard
import com.example.app_mobile.ui.components.DeviceScanDialog
import com.example.app_mobile.ui.components.DirectionControlPad
import com.example.app_mobile.ui.components.LightControlBar
import com.example.app_mobile.ui.components.SpeedControlCard
import com.example.app_mobile.ui.theme.CarbonDarkBg
import com.example.app_mobile.ui.theme.NeonCyan
import com.example.app_mobile.ui.theme.TextPrimary
import com.example.app_mobile.ui.theme.TextSecondary
import com.example.app_mobile.ui.viewmodel.CarViewModel

@Composable
fun CarDashboardScreen(
    viewModel: CarViewModel,
    onRequestPermissions: () -> Unit
) {
    val connectionState by viewModel.connectionState.collectAsState()
    val scannedDevices by viewModel.scannedDevices.collectAsState()
    val lastCommand by viewModel.lastSentCommand.collectAsState()
    val currentSpeed by viewModel.currentSpeed.collectAsState()
    val activeDirection by viewModel.activeDirection.collectAsState()
    val headlightActive by viewModel.headlightActive.collectAsState()
    val leftSignalActive by viewModel.leftSignalActive.collectAsState()
    val rightSignalActive by viewModel.rightSignalActive.collectAsState()
    val hazardActive by viewModel.hazardActive.collectAsState()
    val showScanDialog by viewModel.showScanDialog.collectAsState()

    val isConnected = connectionState is BleConnectionState.Connected

    Scaffold(
        containerColor = CarbonDarkBg
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "DATN CAR COCKPIT",
                        color = TextPrimary,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.ExtraBold,
                        letterSpacing = 1.sp
                    )
                    Text(
                        text = "Raspberry Pi 4 • Qt6 BLE Controller",
                        color = TextSecondary,
                        fontSize = 12.sp
                    )
                }

                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(Color(0xFF1B2433)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = "🏎️", fontSize = 18.sp)
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            ConnectionStatusCard(
                connectionState = connectionState,
                lastCommand = lastCommand,
                onScanClick = {
                    onRequestPermissions()
                    viewModel.setShowScanDialog(true)
                },
                onDisconnectClick = {
                    viewModel.disconnect()
                }
            )

            Spacer(modifier = Modifier.height(14.dp))

            SpeedControlCard(
                currentSpeed = currentSpeed,
                onSpeedChange = { viewModel.setSpeed(it) },
                enabled = isConnected
            )

            Spacer(modifier = Modifier.height(14.dp))

            LightControlBar(
                headlightActive = headlightActive,
                leftSignalActive = leftSignalActive,
                rightSignalActive = rightSignalActive,
                hazardActive = hazardActive,
                enabled = isConnected,
                onToggleHeadlight = { viewModel.toggleHeadlight() },
                onToggleLeftSignal = { viewModel.toggleLeftSignal() },
                onToggleRightSignal = { viewModel.toggleRightSignal() },
                onToggleHazard = { viewModel.toggleHazard() }
            )

            Spacer(modifier = Modifier.height(20.dp))

            DirectionControlPad(
                activeDirection = activeDirection,
                enabled = isConnected,
                onDirectionPress = { viewModel.onDirectionPress(it) },
                onDirectionRelease = { viewModel.onDirectionRelease() },
                onEmergencyStop = { viewModel.emergencyStop() }
            )

            Spacer(modifier = Modifier.height(24.dp))
        }

        if (showScanDialog) {
            DeviceScanDialog(
                devices = scannedDevices,
                isScanning = connectionState is BleConnectionState.Scanning,
                onDeviceSelected = { address ->
                    viewModel.connectDevice(address)
                },
                onRescan = {
                    viewModel.startScan()
                },
                onDismiss = {
                    viewModel.setShowScanDialog(false)
                }
            )
        }
    }
}

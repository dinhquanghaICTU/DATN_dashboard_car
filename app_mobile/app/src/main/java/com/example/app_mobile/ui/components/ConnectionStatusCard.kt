package com.example.app_mobile.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.app_mobile.data.ble.BleConnectionState
import com.example.app_mobile.ui.theme.CardBorder
import com.example.app_mobile.ui.theme.CardDarkBg
import com.example.app_mobile.ui.theme.HazardCrimson
import com.example.app_mobile.ui.theme.NeonCyan
import com.example.app_mobile.ui.theme.SignalAmber
import com.example.app_mobile.ui.theme.StatusGreen
import com.example.app_mobile.ui.theme.StatusGrey
import com.example.app_mobile.ui.theme.TextPrimary
import com.example.app_mobile.ui.theme.TextSecondary

@Composable
fun ConnectionStatusCard(
    connectionState: BleConnectionState,
    lastCommand: String,
    onScanClick: () -> Unit,
    onDisconnectClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(CardDarkBg)
            .border(1.dp, CardBorder, RoundedCornerShape(16.dp))
            .padding(16.dp)
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {

                Row(verticalAlignment = Alignment.CenterVertically) {
                    val (statusColor, statusText) = when (connectionState) {
                        is BleConnectionState.Connected -> Pair(StatusGreen, "ĐÃ KẾT NỐI")
                        is BleConnectionState.Connecting -> Pair(SignalAmber, "ĐANG KẾT NỐI...")
                        is BleConnectionState.Scanning -> Pair(NeonCyan, "ĐANG DÒ XE...")
                        is BleConnectionState.Disconnected -> Pair(StatusGrey, "CHƯA KẾT NỐI")
                        is BleConnectionState.Error -> Pair(HazardCrimson, "LỖI")
                    }

                    Box(
                        modifier = Modifier
                            .size(12.dp)
                            .clip(CircleShape)
                            .background(statusColor)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = statusText,
                        color = statusColor,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp
                    )
                }

                when (connectionState) {
                    is BleConnectionState.Connected -> {
                        OutlinedButton(
                            onClick = onDisconnectClick,
                            shape = RoundedCornerShape(10.dp),
                            border = ButtonDefaults.outlinedButtonBorder.copy(brush = androidx.compose.ui.graphics.SolidColor(HazardCrimson))
                        ) {
                            Text(text = "Ngắt", color = HazardCrimson, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                    is BleConnectionState.Connecting, is BleConnectionState.Scanning -> {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = NeonCyan,
                            strokeWidth = 2.dp
                        )
                    }
                    else -> {
                        Button(
                            onClick = onScanClick,
                            colors = ButtonDefaults.buttonColors(containerColor = NeonCyan),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Text(text = "Dò xe BLE", color = Color.Black, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            val detailText = when (connectionState) {
                is BleConnectionState.Connected -> "${connectionState.deviceName} (${connectionState.address})"
                is BleConnectionState.Connecting -> "Đang thiết lập kênh GATT..."
                is BleConnectionState.Scanning -> "Tìm kiếm thiết bị 'DATN-Car'..."
                is BleConnectionState.Disconnected -> "Chạm 'Dò xe BLE' để kết nối Bluetooth Low Energy"
                is BleConnectionState.Error -> connectionState.message
            }

            Text(
                text = detailText,
                color = TextSecondary,
                fontSize = 13.sp
            )

            AnimatedVisibility(visible = lastCommand.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .background(Color(0xFF0F1520))
                        .padding(horizontal = 10.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(text = "Lệnh gửi Qt:", color = TextSecondary, fontSize = 11.sp)
                    Text(
                        text = lastCommand,
                        color = NeonCyan,
                        fontWeight = FontWeight.Bold,
                        fontSize = 12.sp
                    )
                }
            }
        }
    }
}

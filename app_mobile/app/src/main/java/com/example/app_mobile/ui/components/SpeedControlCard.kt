package com.example.app_mobile.ui.components

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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.app_mobile.ui.theme.CardBorder
import com.example.app_mobile.ui.theme.CardDarkBg
import com.example.app_mobile.ui.theme.NeonCyan
import com.example.app_mobile.ui.theme.TextPrimary
import com.example.app_mobile.ui.theme.TextSecondary

@Composable
fun SpeedControlCard(
    currentSpeed: Int,
    onSpeedChange: (Int) -> Unit,
    enabled: Boolean,
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
                Text(
                    text = "TỐC ĐỘ ĐỘNG CƠ (PWM)",
                    color = TextSecondary,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "$currentSpeed%",
                    color = if (enabled) NeonCyan else TextSecondary,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.ExtraBold
                )
            }

            Spacer(modifier = Modifier.height(6.dp))

            Slider(
                value = currentSpeed.toFloat(),
                onValueChange = { onSpeedChange(it.toInt()) },
                valueRange = 30f..100f,
                steps = 13, // Bước nhảy 5%
                enabled = enabled,
                colors = SliderDefaults.colors(
                    thumbColor = NeonCyan,
                    activeTrackColor = NeonCyan,
                    inactiveTrackColor = Color(0xFF222F44)
                )
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Các nút preset nhanh
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                PresetButton(
                    label = "50% ECO",
                    speed = 50,
                    isSelected = currentSpeed == 50,
                    enabled = enabled,
                    onClick = { onSpeedChange(50) },
                    modifier = Modifier.weight(1f)
                )
                PresetButton(
                    label = "70% CHUẨN",
                    speed = 70,
                    isSelected = currentSpeed == 70,
                    enabled = enabled,
                    onClick = { onSpeedChange(70) },
                    modifier = Modifier.weight(1f)
                )
                PresetButton(
                    label = "100% MAX",
                    speed = 100,
                    isSelected = currentSpeed == 100,
                    enabled = enabled,
                    onClick = { onSpeedChange(100) },
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun PresetButton(
    label: String,
    speed: Int,
    isSelected: Boolean,
    enabled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.height(36.dp),
        shape = RoundedCornerShape(8.dp),
        border = ButtonDefaults.outlinedButtonBorder.copy(
            brush = androidx.compose.ui.graphics.SolidColor(
                if (isSelected) NeonCyan else CardBorder
            )
        ),
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = if (isSelected) NeonCyan.copy(alpha = 0.15f) else Color.Transparent
        )
    ) {
        Text(
            text = label,
            fontSize = 11.sp,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            color = if (isSelected) NeonCyan else TextPrimary
        )
    }
}

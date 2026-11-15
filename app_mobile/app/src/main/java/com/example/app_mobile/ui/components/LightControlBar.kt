package com.example.app_mobile.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
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
import com.example.app_mobile.ui.theme.HazardCrimson
import com.example.app_mobile.ui.theme.NeonCyan
import com.example.app_mobile.ui.theme.SignalAmber
import com.example.app_mobile.ui.theme.TextPrimary
import com.example.app_mobile.ui.theme.TextSecondary

@Composable
fun LightControlBar(
    headlightActive: Boolean,
    leftSignalActive: Boolean,
    rightSignalActive: Boolean,
    hazardActive: Boolean,
    enabled: Boolean,
    onToggleHeadlight: () -> Unit,
    onToggleLeftSignal: () -> Unit,
    onToggleRightSignal: () -> Unit,
    onToggleHazard: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(CardDarkBg)
            .border(1.dp, CardBorder, RoundedCornerShape(16.dp))
            .padding(14.dp)
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = "HỆ THỐNG ĐÈN & TÍN HIỆU",
                color = TextSecondary,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Xi-nhan Trái (TL)
                LightButton(
                    icon = "⇦",
                    label = "XI-NHAN T",
                    isActive = leftSignalActive,
                    activeColor = SignalAmber,
                    enabled = enabled,
                    onClick = onToggleLeftSignal,
                    modifier = Modifier.weight(1f)
                )

                // Đèn Pha (LAMP)
                LightButton(
                    icon = "💡",
                    label = "ĐÈN PHA",
                    isActive = headlightActive,
                    activeColor = NeonCyan,
                    enabled = enabled,
                    onClick = onToggleHeadlight,
                    modifier = Modifier.weight(1f)
                )

                // Đèn Khẩn cấp (HAZ)
                LightButton(
                    icon = "⚠️",
                    label = "HAZARD",
                    isActive = hazardActive,
                    activeColor = HazardCrimson,
                    enabled = enabled,
                    onClick = onToggleHazard,
                    modifier = Modifier.weight(1f)
                )

                // Xi-nhan Phải (TR)
                LightButton(
                    icon = "⇨",
                    label = "XI-NHAN P",
                    isActive = rightSignalActive,
                    activeColor = SignalAmber,
                    enabled = enabled,
                    onClick = onToggleRightSignal,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun LightButton(
    icon: String,
    label: String,
    isActive: Boolean,
    activeColor: Color,
    enabled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val bgColor = when {
        !enabled -> Color(0xFF131923)
        isActive -> activeColor.copy(alpha = 0.2f)
        else -> Color(0xFF1B2433)
    }

    val borderColor = when {
        !enabled -> CardBorder
        isActive -> activeColor
        else -> CardBorder
    }

    val contentColor = when {
        !enabled -> Color(0xFF4A5568)
        isActive -> activeColor
        else -> TextPrimary
    }

    Box(
        modifier = modifier
            .height(64.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(bgColor)
            .border(1.5.dp, borderColor, RoundedCornerShape(12.dp))
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = icon,
                color = contentColor,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = label,
                color = contentColor,
                fontSize = 9.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

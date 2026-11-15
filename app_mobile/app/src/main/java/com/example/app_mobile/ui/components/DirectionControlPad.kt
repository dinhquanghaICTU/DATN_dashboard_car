package com.example.app_mobile.ui.components

import android.view.HapticFeedbackConstants
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.app_mobile.data.model.DriveDirection
import com.example.app_mobile.ui.theme.ControlButtonBorder
import com.example.app_mobile.ui.theme.ControlButtonNormal
import com.example.app_mobile.ui.theme.HazardCrimson
import com.example.app_mobile.ui.theme.NeonCyan
import com.example.app_mobile.ui.theme.TextPrimary

@Composable
fun DirectionControlPad(
    activeDirection: DriveDirection?,
    enabled: Boolean,
    onDirectionPress: (DriveDirection) -> Unit,
    onDirectionRelease: () -> Unit,
    onEmergencyStop: () -> Unit,
    modifier: Modifier = Modifier
) {
    val buttonSize = 78.dp

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Nút TIẾN
        DirectionButton(
            icon = "▲",
            label = "TIẾN",
            isActive = activeDirection == DriveDirection.FORWARD,
            enabled = enabled,
            size = buttonSize,
            onPress = { onDirectionPress(DriveDirection.FORWARD) },
            onRelease = onDirectionRelease
        )

        Spacer(modifier = Modifier.height(10.dp))

        // Hàng giữa: TRÁI - DỪNG - PHẢI
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            // Nút RẼ TRÁI
            DirectionButton(
                icon = "◀",
                label = "TRÁI",
                isActive = activeDirection == DriveDirection.LEFT,
                enabled = enabled,
                size = buttonSize,
                onPress = { onDirectionPress(DriveDirection.LEFT) },
                onRelease = onDirectionRelease
            )

            Spacer(modifier = Modifier.width(12.dp))

            // Nút PHANH / DỪNG ở giữa
            StopButton(
                enabled = enabled,
                size = buttonSize,
                onClick = onEmergencyStop
            )

            Spacer(modifier = Modifier.width(12.dp))

            // Nút RẼ PHẢI
            DirectionButton(
                icon = "▶",
                label = "PHẢI",
                isActive = activeDirection == DriveDirection.RIGHT,
                enabled = enabled,
                size = buttonSize,
                onPress = { onDirectionPress(DriveDirection.RIGHT) },
                onRelease = onDirectionRelease
            )
        }

        Spacer(modifier = Modifier.height(10.dp))

        // Nút LÙI
        DirectionButton(
            icon = "▼",
            label = "LÙI",
            isActive = activeDirection == DriveDirection.BACKWARD,
            enabled = enabled,
            size = buttonSize,
            onPress = { onDirectionPress(DriveDirection.BACKWARD) },
            onRelease = onDirectionRelease
        )
    }
}

@Composable
private fun DirectionButton(
    icon: String,
    label: String,
    isActive: Boolean,
    enabled: Boolean,
    size: Dp,
    onPress: () -> Unit,
    onRelease: () -> Unit
) {
    val view = LocalView.current

    val bgColor = when {
        !enabled -> Color(0xFF131923)
        isActive -> NeonCyan
        else -> ControlButtonNormal
    }

    val contentColor = when {
        !enabled -> Color(0xFF3B485A)
        isActive -> Color.Black
        else -> TextPrimary
    }

    val borderColor = when {
        isActive -> NeonCyan
        else -> ControlButtonBorder
    }

    Box(
        modifier = Modifier
            .size(size)
            .clip(RoundedCornerShape(20.dp))
            .background(bgColor)
            .border(2.dp, borderColor, RoundedCornerShape(20.dp))
            .pointerInput(enabled) {
                if (!enabled) return@pointerInput
                detectTapGestures(
                    onPress = {
                        view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                        onPress()
                        tryAwaitRelease()
                        onRelease()
                    }
                )
            },
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = icon,
                color = contentColor,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = label,
                color = contentColor,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

@Composable
private fun StopButton(
    enabled: Boolean,
    size: Dp,
    onClick: () -> Unit
) {
    val view = LocalView.current

    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(if (enabled) HazardCrimson else Color(0xFF2C151B))
            .border(2.dp, if (enabled) Color(0xFFFF5252) else Color(0xFF4A1F26), CircleShape)
            .pointerInput(enabled) {
                if (!enabled) return@pointerInput
                detectTapGestures(
                    onTap = {
                        view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                        onClick()
                    }
                )
            },
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "STOP",
                color = Color.White,
                fontSize = 15.sp,
                fontWeight = FontWeight.ExtraBold
            )
            Text(
                text = "PHANH",
                color = Color.White.copy(alpha = 0.8f),
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

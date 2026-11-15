package com.example.app_mobile.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColorScheme = darkColorScheme(
    primary = NeonCyan,
    onPrimary = Color.Black,
    secondary = ElectricBlue,
    onSecondary = Color.White,
    tertiary = SignalAmber,
    background = CarbonDarkBg,
    onBackground = TextPrimary,
    surface = CardDarkBg,
    onSurface = TextPrimary,
    surfaceVariant = CardBorder,
    onSurfaceVariant = TextSecondary
)

@Composable
fun App_mobileTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = Typography,
        content = content
    )
}

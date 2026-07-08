package com.virgax.arise.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import com.virgax.arise.domain.Rank
import com.virgax.arise.domain.StatKind

object AriseColors {
    val Background = Color(0xFF05070F)
    val Panel = Color(0xFF0C1426)
    val PanelStroke = Color(0xFF2FA8FF)
    val Accent = Color(0xFF35C2FF)
    val AccentDeep = Color(0xFF1E6BFF)
    val Glow = Color(0xFF5BD6FF)
    val Danger = Color(0xFFFF4D6D)
    val Gold = Color(0xFFFFC857)
    val TextPrimary = Color(0xFFEAF4FF)
    val TextSecondary = Color(0xFF8FA6C4)
}

fun rankColor(r: Rank): Color = when (r) {
    Rank.E -> Color(0xFF8FA6C4)
    Rank.D -> Color(0xFF4ED2A0)
    Rank.C -> Color(0xFF35C2FF)
    Rank.B -> Color(0xFF9B6BFF)
    Rank.A -> Color(0xFFFFC857)
    Rank.S -> Color(0xFFFF8A3D)
    Rank.MONARCH -> Color(0xFFFF4D6D)
}

fun statColor(k: StatKind): Color = when (k) {
    StatKind.STRENGTH -> Color(0xFFFF6B6B)
    StatKind.AGILITY -> Color(0xFF4ED2A0)
    StatKind.VITALITY -> Color(0xFFFF4D6D)
    StatKind.ENDURANCE -> Color(0xFFFF8A3D)
    StatKind.SENSE -> Color(0xFF9B6BFF)
}

private val AriseScheme = darkColorScheme(
    primary = AriseColors.Accent,
    onPrimary = Color.Black,
    secondary = AriseColors.AccentDeep,
    background = AriseColors.Background,
    onBackground = AriseColors.TextPrimary,
    surface = AriseColors.Panel,
    onSurface = AriseColors.TextPrimary,
    surfaceVariant = AriseColors.Panel,
    onSurfaceVariant = AriseColors.TextSecondary,
    error = AriseColors.Danger,
)

@Composable
fun AriseTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = AriseScheme,
        typography = Typography(),
        content = content,
    )
}

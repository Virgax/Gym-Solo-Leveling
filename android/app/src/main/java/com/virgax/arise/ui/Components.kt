package com.virgax.arise.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.virgax.arise.domain.Rank
import com.virgax.arise.domain.StatKind
import com.virgax.arise.ui.theme.AriseColors
import com.virgax.arise.ui.theme.rankColor

fun statIcon(kind: StatKind): ImageVector = when (kind) {
    StatKind.STRENGTH -> Icons.Filled.FitnessCenter
    StatKind.AGILITY -> Icons.Filled.DirectionsRun
    StatKind.VITALITY -> Icons.Filled.Favorite
    StatKind.ENDURANCE -> Icons.Filled.LocalFireDepartment
    StatKind.SENSE -> Icons.Filled.Bedtime
}

@Composable
fun SystemPanel(
    title: String? = null,
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(AriseColors.Panel)
            .border(1.dp, AriseColors.PanelStroke.copy(alpha = 0.45f), RoundedCornerShape(14.dp))
            .padding(16.dp)
    ) {
        if (title != null) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(width = 3.dp, height = 16.dp).background(AriseColors.Accent))
                Spacer(Modifier.width(8.dp))
                Text(
                    title.uppercase(),
                    color = AriseColors.TextPrimary,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 2.sp,
                    fontSize = 13.sp,
                )
            }
            Spacer(Modifier.height(12.dp))
        }
        content()
    }
}

@Composable
fun ProgressLine(fraction: Double, color: Color, modifier: Modifier = Modifier, height: Int = 8) {
    Box(
        modifier
            .fillMaxWidth()
            .height(height.dp)
            .clip(RoundedCornerShape(50))
            .background(Color.White.copy(alpha = 0.06f))
    ) {
        Box(
            Modifier
                .fillMaxWidth(fraction.coerceIn(0.0, 1.0).toFloat())
                .height(height.dp)
                .clip(RoundedCornerShape(50))
                .background(
                    Brush.horizontalGradient(listOf(color.copy(alpha = 0.6f), color))
                )
        )
    }
}

@Composable
fun RankBadge(rank: Rank, size: Int = 64) {
    val c = rankColor(rank)
    Box(
        Modifier
            .size(size.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(c.copy(alpha = 0.18f))
            .border(2.dp, c, RoundedCornerShape(14.dp)),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            if (rank == Rank.MONARCH) "M" else rank.label,
            color = c,
            fontWeight = FontWeight.Black,
            fontFamily = FontFamily.SansSerif,
            fontSize = (size / 2.4f).sp,
        )
    }
}

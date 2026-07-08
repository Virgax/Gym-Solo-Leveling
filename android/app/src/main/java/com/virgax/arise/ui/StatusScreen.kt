package com.virgax.arise.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.virgax.arise.AriseViewModel
import com.virgax.arise.domain.BodyProfile
import com.virgax.arise.domain.Stat
import com.virgax.arise.ui.theme.AriseColors
import com.virgax.arise.ui.theme.rankColor
import com.virgax.arise.ui.theme.statColor

@Composable
fun StatusScreen(vm: AriseViewModel) {
    ScreenContainer {
        Text(
            "THE SYSTEM",
            color = AriseColors.Accent,
            fontWeight = FontWeight.Bold,
            letterSpacing = 3.sp,
            fontSize = 13.sp,
        )
        StreakChip(vm.streak)
        StatusPanel(vm)
        VitalsPanel(vm.body)
    }
}

@Composable
private fun StreakChip(streak: Int) {
    SystemPanel {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.Whatshot, null, tint = if (streak > 0) AriseColors.Gold else AriseColors.TextSecondary)
            Spacer(Modifier.width(10.dp))
            Text(
                if (streak > 0) "$streak-day streak" else "No active streak",
                color = AriseColors.TextPrimary, fontWeight = FontWeight.Bold,
            )
            Spacer(Modifier.weight(1f))
            Text("Keep clearing daily quests", color = AriseColors.TextSecondary, fontSize = 11.sp)
        }
    }
}

@Composable
private fun StatusPanel(vm: AriseViewModel) {
    SystemPanel("Status") {
        Row(verticalAlignment = Alignment.CenterVertically) {
            RankBadge(vm.rank)
            Spacer(Modifier.width(16.dp))
            Column(Modifier.weight(1f)) {
                Text(vm.hunterName, color = AriseColors.TextPrimary, fontWeight = FontWeight.Black, fontSize = 24.sp)
                Text(vm.rank.title, color = rankColor(vm.rank), fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("LV", color = AriseColors.TextSecondary, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                Text("${vm.level}", color = AriseColors.Accent, fontWeight = FontWeight.Black, fontSize = 36.sp)
            }
        }
        Spacer(Modifier.height(14.dp))
        val (into, span) = vm.xpProgress
        Row(Modifier.fillMaxWidth()) {
            Text("EXP", color = AriseColors.TextSecondary, fontSize = 11.sp)
            Spacer(Modifier.weight(1f))
            Text("$into / $span", color = AriseColors.TextSecondary, fontSize = 11.sp)
        }
        Spacer(Modifier.height(4.dp))
        ProgressLine(if (span > 0) into.toDouble() / span else 1.0, AriseColors.Accent)
        Spacer(Modifier.height(14.dp))
        Divider(color = AriseColors.PanelStroke.copy(alpha = 0.3f))
        Spacer(Modifier.height(14.dp))
        vm.stats.forEachIndexed { i, stat ->
            StatRow(stat)
            if (i < vm.stats.lastIndex) Spacer(Modifier.height(12.dp))
        }
    }
}

@Composable
private fun StatRow(stat: Stat) {
    val c = statColor(stat.kind)
    Column {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(statIcon(stat.kind), null, tint = c, modifier = Modifier.width(24.dp))
            Spacer(Modifier.width(10.dp))
            Text(stat.kind.abbr, color = AriseColors.TextPrimary, fontWeight = FontWeight.Bold)
            Spacer(Modifier.weight(1f))
            Text("${stat.value}", color = c, fontWeight = FontWeight.Black, fontSize = 18.sp)
        }
        Spacer(Modifier.height(6.dp))
        ProgressLine(stat.condition, c, height = 6)
    }
}

@Composable
private fun VitalsPanel(body: BodyProfile) {
    SystemPanel("Vitals & Targets") {
        val t = body.targets
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Metric("BMI", String.format("%.1f", body.bmi), body.bmiCategory, AriseColors.Accent)
            Metric("BMR", "${body.bmr.toInt()}", "kcal", AriseColors.Gold)
            Metric("TDEE", "${body.tdee.toInt()}", "kcal/day", AriseColors.Glow)
        }
        Spacer(Modifier.height(12.dp))
        Divider(color = AriseColors.PanelStroke.copy(alpha = 0.3f))
        Spacer(Modifier.height(12.dp))
        TargetRow("Calories", "${t.calories} kcal", body.goal.label)
        TargetRow("Protein", "${t.proteinG} g", "muscle fuel")
        TargetRow("Water", "${t.waterMl} mL", "≈${t.waterMl / 250} glasses")
        TargetRow("Caffeine limit", "${t.caffeineLimitMg} mg", "stay under")
    }
}

@Composable
private fun Metric(label: String, value: String, sub: String, color: androidx.compose.ui.graphics.Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(label, color = AriseColors.TextSecondary, fontSize = 11.sp, fontWeight = FontWeight.Bold)
        Text(value, color = color, fontWeight = FontWeight.Black, fontSize = 22.sp)
        Text(sub, color = AriseColors.TextSecondary, fontSize = 9.sp)
    }
}

@Composable
private fun TargetRow(label: String, value: String, sub: String) {
    Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, color = AriseColors.TextPrimary, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
        Spacer(Modifier.weight(1f))
        Text(value, color = AriseColors.Accent, fontWeight = FontWeight.Bold, fontSize = 14.sp)
        Spacer(Modifier.width(8.dp))
        Text(sub, color = AriseColors.TextSecondary, fontSize = 11.sp)
    }
}

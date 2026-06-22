package com.virgax.arise.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.virgax.arise.AriseViewModel
import com.virgax.arise.domain.ActivityLevel
import com.virgax.arise.domain.BodyProfile
import com.virgax.arise.domain.Goal
import com.virgax.arise.domain.Sex
import com.virgax.arise.ui.theme.AriseColors
import java.time.LocalDate

@Composable
fun OnboardingScreen(vm: AriseViewModel) {
    var name by remember { mutableStateOf("Hunter") }
    var sex by remember { mutableStateOf(Sex.MALE) }
    var age by remember { mutableFloatStateOf(25f) }
    var heightCm by remember { mutableFloatStateOf(175f) }
    var weightKg by remember { mutableFloatStateOf(75f) }
    var activity by remember { mutableStateOf(ActivityLevel.MODERATE) }
    var goal by remember { mutableStateOf(Goal.MAINTAIN) }

    val profile = BodyProfile(sex, LocalDate.now().year - age.toInt(), heightCm.toDouble(), weightKg.toDouble(), activity, goal)

    ScreenContainer {
        Text("THE SYSTEM HAS CHOSEN YOU", color = AriseColors.TextPrimary, fontWeight = FontWeight.Black, fontSize = 26.sp)
        Text(
            "Set up your Hunter. (On Android, your training, sleep and body data will come from Health Connect — Fitbit, Google Health and your ring all sync there.)",
            color = AriseColors.TextSecondary, fontSize = 14.sp,
        )

        SystemPanel("Your Vessel") {
            OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Hunter name") }, modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(12.dp))

            Label("Sex")
            ChipRow(Sex.entries.map { it.label }, Sex.entries.indexOf(sex)) { sex = Sex.entries[it] }

            Slider("Age", age, 14f..90f) { age = it }
            Slider("Height", heightCm, 120f..220f, unit = "cm") { heightCm = it }
            Slider("Weight", weightKg, 35f..200f, unit = "kg") { weightKg = it }

            Label("Activity")
            ChipRow(ActivityLevel.entries.map { it.label }, ActivityLevel.entries.indexOf(activity)) { activity = ActivityLevel.entries[it] }

            Label("Goal")
            ChipRow(Goal.entries.map { it.label }, Goal.entries.indexOf(goal)) { goal = Goal.entries[it] }
        }

        BodyStatsPreview(profile)

        Button(onClick = { vm.completeOnboarding(name, profile) }, modifier = Modifier.fillMaxWidth()) {
            Text("AWAKEN", fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
        }
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun BodyStatsPreview(body: BodyProfile) {
    SystemPanel("System Calibration") {
        val t = body.targets
        Text("BMI ${String.format("%.1f", body.bmi)} (${body.bmiCategory})", color = AriseColors.Accent, fontWeight = FontWeight.Bold)
        Text("TDEE ${body.tdee.toInt()} kcal/day", color = AriseColors.TextSecondary, fontSize = 13.sp)
        Spacer(Modifier.height(8.dp))
        Text("Targets → ${t.calories} kcal · ${t.proteinG} g protein · ${t.waterMl} mL water", color = AriseColors.TextSecondary, fontSize = 13.sp)
    }
}

@Composable
private fun Label(text: String) {
    Text(text.uppercase(), color = AriseColors.TextSecondary, fontSize = 11.sp, fontWeight = FontWeight.Bold)
    Spacer(Modifier.height(6.dp))
}

@Composable
private fun ChipRow(options: List<String>, selectedIndex: Int, onSelect: (Int) -> Unit) {
    androidx.compose.foundation.layout.FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        options.forEachIndexed { i, label ->
            FilterChip(
                selected = i == selectedIndex,
                onClick = { onSelect(i) },
                label = { Text(label) },
                colors = FilterChipDefaults.filterChipColors(selectedContainerColor = AriseColors.AccentDeep),
            )
        }
    }
    Spacer(Modifier.height(12.dp))
}

@Composable
private fun Slider(label: String, value: Float, range: ClosedFloatingPointRange<Float>, unit: String = "", onChange: (Float) -> Unit) {
    Text("$label · ${value.toInt()} $unit".trim(), color = AriseColors.TextSecondary, fontSize = 11.sp, fontWeight = FontWeight.Bold)
    androidx.compose.material3.Slider(value = value, onValueChange = onChange, valueRange = range)
    Spacer(Modifier.height(6.dp))
}

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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.text.KeyboardOptions
import com.virgax.arise.AriseViewModel
import com.virgax.arise.domain.MealEntry
import com.virgax.arise.domain.MealType
import com.virgax.arise.ui.theme.AriseColors
import java.util.UUID

@Composable
fun FuelScreen(vm: AriseViewModel) {
    var addingType by remember { mutableStateOf<MealType?>(null) }

    ScreenContainer {
        val t = vm.targets
        val consumed = vm.meals.sumOf { it.calories }

        SystemPanel("Daily Fuel") {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Big("$consumed", "eaten"); Big("${t.calories}", "target"); Big("${(t.calories - consumed).coerceAtLeast(0)}", "left")
            }
            Spacer(Modifier.height(12.dp))
            ProgressLine(if (t.calories > 0) consumed.toDouble() / t.calories else 0.0, AriseColors.Gold)
            Spacer(Modifier.height(8.dp))
            Text(
                "${vm.meals.sumOf { it.proteinG ?: 0.0 }.toInt()} / ${t.proteinG} g protein",
                color = AriseColors.TextSecondary, fontSize = 12.sp,
            )
        }

        SystemPanel("Hydration") {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("${vm.waterMl} mL", color = AriseColors.TextPrimary, fontWeight = FontWeight.Black, fontSize = 22.sp)
                Spacer(Modifier.width(6.dp))
                Text("/ ${t.waterMl} mL", color = AriseColors.TextSecondary, fontSize = 13.sp)
            }
            Spacer(Modifier.height(10.dp))
            ProgressLine(if (t.waterMl > 0) vm.waterMl.toDouble() / t.waterMl else 0.0, AriseColors.Accent)
            Spacer(Modifier.height(12.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Quick("＋ Glass", "250 mL") { vm.addWater(250) }
                Quick("＋ Bottle", "500 mL") { vm.addWater(500) }
                Quick("－", "250 mL") { vm.addWater(-250) }
            }
        }

        SystemPanel("Caffeine") {
            val over = vm.caffeineMg > t.caffeineLimitMg
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("${vm.caffeineMg} mg", color = if (over) AriseColors.Danger else AriseColors.TextPrimary, fontWeight = FontWeight.Black, fontSize = 22.sp)
                Spacer(Modifier.width(6.dp))
                Text("/ ${t.caffeineLimitMg} mg", color = AriseColors.TextSecondary, fontSize = 13.sp)
            }
            Spacer(Modifier.height(10.dp))
            ProgressLine(if (t.caffeineLimitMg > 0) vm.caffeineMg.toDouble() / t.caffeineLimitMg else 0.0, if (over) AriseColors.Danger else AriseColors.Gold)
            Spacer(Modifier.height(12.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Quick("Coffee", "95 mg") { vm.addCaffeine(95) }
                Quick("Espresso", "63 mg") { vm.addCaffeine(63) }
                Quick("Energy", "160 mg") { vm.addCaffeine(160) }
            }
        }

        SystemPanel("Meal Schedule") {
            MealType.entries.forEach { type ->
                val items = vm.meals.filter { it.type == type }
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text(type.display, color = AriseColors.TextPrimary, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.width(8.dp))
                    Text(String.format("%02d:00", type.suggestedHour), color = AriseColors.TextSecondary, fontSize = 11.sp)
                    Spacer(Modifier.weight(1f))
                    val kcal = items.sumOf { it.calories }
                    if (kcal > 0) Text("$kcal kcal", color = AriseColors.Gold, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    IconButton(onClick = { addingType = type }) {
                        Icon(Icons.Filled.Add, "Add", tint = AriseColors.Accent)
                    }
                }
                items.forEach { e ->
                    Row(Modifier.fillMaxWidth().padding(start = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text("• ${e.name}", color = AriseColors.TextSecondary, fontSize = 12.sp)
                        Spacer(Modifier.weight(1f))
                        Text("${e.calories} kcal", color = AriseColors.TextSecondary, fontSize = 11.sp)
                        TextButton(onClick = { vm.removeMeal(e.id) }) { Text("✕", color = AriseColors.TextSecondary) }
                    }
                }
                Spacer(Modifier.height(8.dp))
            }
        }
    }

    addingType?.let { type ->
        AddMealDialog(type, onDismiss = { addingType = null }) { entry ->
            vm.logMeal(entry); addingType = null
        }
    }
}

@Composable
private fun Big(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, color = AriseColors.TextPrimary, fontWeight = FontWeight.Black, fontSize = 26.sp)
        Text(label, color = AriseColors.TextSecondary, fontSize = 11.sp)
    }
}

@Composable
private fun Quick(title: String, sub: String, onClick: () -> Unit) {
    OutlinedButton(onClick = onClick) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(title, color = AriseColors.TextPrimary, fontWeight = FontWeight.Bold, fontSize = 13.sp)
            Text(sub, color = AriseColors.TextSecondary, fontSize = 9.sp)
        }
    }
}

@Composable
private fun AddMealDialog(type: MealType, onDismiss: () -> Unit, onSave: (MealEntry) -> Unit) {
    var name by remember { mutableStateOf("") }
    var calories by remember { mutableStateOf("") }
    var protein by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Log ${type.display}") },
        text = {
            Column {
                OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("What did you eat?") })
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(value = calories, onValueChange = { calories = it }, label = { Text("Calories (kcal)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number))
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(value = protein, onValueChange = { protein = it }, label = { Text("Protein (g, optional)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number))
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val kcal = calories.toIntOrNull() ?: 0
                    onSave(MealEntry(UUID.randomUUID().toString(), type, name.ifBlank { type.display }, kcal, protein.toDoubleOrNull()))
                },
                enabled = (calories.toIntOrNull() ?: 0) > 0,
            ) { Text("Add") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

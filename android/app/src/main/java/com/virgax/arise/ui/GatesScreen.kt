package com.virgax.arise.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.virgax.arise.AriseViewModel
import com.virgax.arise.domain.Routine
import com.virgax.arise.domain.RoutineExercise
import com.virgax.arise.domain.RoutineLibrary
import com.virgax.arise.ui.theme.AriseColors

@Composable
fun GatesScreen(vm: AriseViewModel) {
    var active by remember { mutableStateOf<Routine?>(null) }

    val current = active
    if (current != null) {
        GateSession(current, onClear = { vm.completeGate(current); active = null }, onBack = { active = null })
        return
    }

    ScreenContainer {
        Text("GATES", color = AriseColors.TextPrimary, fontWeight = FontWeight.Black, fontSize = 30.sp)
        Text(
            "Clear a Gate to earn XP and raise STR & END. Each is a structured routine — sets, reps and rest.",
            color = AriseColors.TextSecondary, fontSize = 14.sp,
        )
        RoutineLibrary.all.forEach { routine ->
            RoutineCard(routine, cleared = vm.clearedGateIds.contains(routine.id)) { active = routine }
        }
    }
}

@Composable
private fun RoutineCard(routine: Routine, cleared: Boolean, onClick: () -> Unit) {
    SystemPanel(modifier = Modifier.clickable(onClick = onClick)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            RankBadge(routine.gateRank, size = 50)
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(routine.name, color = AriseColors.TextPrimary, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                    if (cleared) {
                        Spacer(Modifier.width(6.dp))
                        Icon(Icons.Filled.CheckCircle, null, tint = AriseColors.Accent, modifier = Modifier.size(16.dp))
                    }
                }
                Text(routine.subtitle, color = AriseColors.TextSecondary, fontSize = 12.sp)
                Spacer(Modifier.height(4.dp))
                Text(
                    "${routine.estMinutes}m · ${routine.totalSets} sets · +${routine.xpReward} XP",
                    color = AriseColors.Accent, fontSize = 11.sp,
                )
            }
        }
    }
}

@Composable
private fun GateSession(routine: Routine, onClear: () -> Unit, onBack: () -> Unit) {
    val done = remember(routine.id) { mutableStateMapOf<String, Int>() }
    val totalSets = routine.totalSets
    val doneSets = routine.exercises.sumOf { done[it.exercise.id] ?: 0 }
    val isCleared = doneSets >= totalSets

    ScreenContainer {
        Row(verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onBack) { Text("‹ Back", color = AriseColors.Accent) }
            Spacer(Modifier.weight(1f))
            Text("$doneSets / $totalSets sets", color = AriseColors.Accent, fontWeight = FontWeight.Bold)
        }
        Text(routine.name, color = AriseColors.TextPrimary, fontWeight = FontWeight.Black, fontSize = 24.sp)
        ProgressLine(if (totalSets > 0) doneSets.toDouble() / totalSets else 0.0, AriseColors.Accent)

        routine.exercises.forEach { re ->
            ExerciseCard(re, done[re.exercise.id] ?: 0) { idx ->
                val cur = done[re.exercise.id] ?: 0
                done[re.exercise.id] = if (idx + 1 == cur) idx else (idx + 1).coerceAtMost(re.sets)
            }
        }

        Button(
            onClick = onClear,
            enabled = isCleared,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(if (isCleared) "CLEAR GATE  ·  +${routine.xpReward} XP" else "Complete all sets to clear")
        }
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun ExerciseCard(re: RoutineExercise, doneSets: Int, onTap: (Int) -> Unit) {
    SystemPanel {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(statIconForMuscle(), null, tint = AriseColors.Accent)
            Spacer(Modifier.width(8.dp))
            Text(re.exercise.name, color = AriseColors.TextPrimary, fontWeight = FontWeight.Bold)
            Spacer(Modifier.weight(1f))
            Text(re.reps, color = AriseColors.Gold, fontWeight = FontWeight.Bold, fontSize = 13.sp)
        }
        Spacer(Modifier.height(6.dp))
        Text(re.exercise.cue, color = AriseColors.TextSecondary, fontSize = 12.sp)
        Spacer(Modifier.height(8.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
            for (i in 0 until re.sets) {
                val filled = i < doneSets
                Box(
                    Modifier
                        .size(34.dp)
                        .clip(CircleShape)
                        .background(if (filled) AriseColors.Accent else Color.White.copy(alpha = 0.06f))
                        .border(1.dp, AriseColors.PanelStroke.copy(alpha = 0.6f), CircleShape)
                        .clickable { onTap(i) },
                    contentAlignment = Alignment.Center,
                ) {
                    Text("${i + 1}", color = if (filled) Color.Black else AriseColors.TextSecondary, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
            }
            Spacer(Modifier.weight(1f))
            Text("${re.restSeconds}s rest", color = AriseColors.TextSecondary, fontSize = 11.sp)
        }
    }
}

@Composable
private fun statIconForMuscle() = Icons.Filled.Bolt

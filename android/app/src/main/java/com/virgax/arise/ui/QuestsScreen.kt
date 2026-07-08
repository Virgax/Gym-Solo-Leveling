package com.virgax.arise.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.virgax.arise.AriseViewModel
import com.virgax.arise.domain.Quest
import com.virgax.arise.domain.QuestCategory
import com.virgax.arise.ui.theme.AriseColors

@Composable
fun QuestsScreen(vm: AriseViewModel) {
    ScreenContainer {
        Group("Training Quests", vm.quests.filter { it.category == QuestCategory.TRAINING })
        Group("Fuel Quests", vm.quests.filter { it.category == QuestCategory.FUEL })
        Group("Recovery Quests", vm.quests.filter { it.category == QuestCategory.RECOVERY })
    }
}

@Composable
private fun Group(title: String, quests: List<Quest>) {
    if (quests.isEmpty()) return
    SystemPanel(title) {
        quests.forEachIndexed { i, q ->
            QuestRow(q)
            if (i < quests.lastIndex) Spacer(Modifier.height(14.dp))
        }
    }
}

@Composable
private fun QuestRow(q: Quest) {
    Row(verticalAlignment = Alignment.Top) {
        Icon(
            if (q.complete) Icons.Filled.CheckCircle else Icons.Filled.RadioButtonUnchecked,
            null,
            tint = if (q.complete) AriseColors.Accent else AriseColors.TextSecondary,
            modifier = Modifier.width(24.dp),
        )
        Spacer(Modifier.width(12.dp))
        Column(Modifier.fillMaxWidth()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(q.title, color = AriseColors.TextPrimary, fontWeight = FontWeight.Bold)
                if (q.mandatory) {
                    Spacer(Modifier.width(6.dp))
                    Text("REQ", color = AriseColors.Danger, fontSize = 9.sp, fontWeight = FontWeight.Black)
                }
                Spacer(Modifier.weight(1f))
                Text("+${q.xpReward} XP", color = AriseColors.Gold, fontSize = 11.sp, fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.height(5.dp))
            ProgressLine(q.fraction, AriseColors.Accent, height = 5)
            Spacer(Modifier.height(3.dp))
            Text(q.progressText, color = AriseColors.TextSecondary, fontSize = 11.sp)
        }
    }
}

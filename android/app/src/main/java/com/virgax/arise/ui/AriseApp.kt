package com.virgax.arise.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Checklist
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.virgax.arise.AriseViewModel
import com.virgax.arise.ui.theme.AriseColors

private enum class Dest(val label: String, val icon: ImageVector) {
    STATUS("Status", Icons.Filled.Person),
    GATES("Gates", Icons.Filled.GridView),
    FUEL("Fuel", Icons.Filled.Restaurant),
    QUESTS("Quests", Icons.Filled.Checklist),
}

/** Adaptive scaffold: bottom bar on compact widths (phones, flip, folded),
 *  navigation rail on wide widths (tablets, unfolded foldables, landscape). */
@Composable
fun AriseApp(vm: AriseViewModel = viewModel()) {
    if (!vm.onboardingDone) {
        OnboardingScreen(vm)
        return
    }
    var dest by remember { mutableStateOf(Dest.STATUS) }

    BoxWithConstraints(Modifier.fillMaxSize().background(AriseColors.Background)) {
        val wide = maxWidth >= 600.dp
        if (wide) {
            Row(Modifier.fillMaxSize()) {
                NavigationRail(containerColor = AriseColors.Panel) {
                    Dest.entries.forEach { d ->
                        NavigationRailItem(
                            selected = d == dest,
                            onClick = { dest = d },
                            icon = { Icon(d.icon, d.label) },
                            label = { Text(d.label) },
                        )
                    }
                }
                Box(Modifier.fillMaxSize()) { Content(vm, dest) }
            }
        } else {
            Scaffold(
                containerColor = AriseColors.Background,
                bottomBar = {
                    NavigationBar(containerColor = AriseColors.Panel) {
                        Dest.entries.forEach { d ->
                            NavigationBarItem(
                                selected = d == dest,
                                onClick = { dest = d },
                                icon = { Icon(d.icon, d.label) },
                                label = { Text(d.label) },
                                colors = NavigationBarItemDefaults.colors(
                                    selectedIconColor = AriseColors.Accent,
                                    selectedTextColor = AriseColors.Accent,
                                    indicatorColor = AriseColors.AccentDeep,
                                ),
                            )
                        }
                    }
                },
            ) { pad ->
                Box(Modifier.padding(pad)) { Content(vm, dest) }
            }
        }
    }
}

@Composable
private fun Content(vm: AriseViewModel, dest: Dest) {
    when (dest) {
        Dest.STATUS -> StatusScreen(vm)
        Dest.GATES -> GatesScreen(vm)
        Dest.FUEL -> FuelScreen(vm)
        Dest.QUESTS -> QuestsScreen(vm)
    }
}

/** Scrollable, width-constrained container so content reads well on any size. */
@Composable
fun ScreenContainer(content: @Composable ColumnScope.() -> Unit) {
    Box(
        Modifier.fillMaxSize().background(AriseColors.Background),
        contentAlignment = Alignment.TopCenter,
    ) {
        Column(
            Modifier
                .widthIn(max = 640.dp)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            content()
        }
    }
}

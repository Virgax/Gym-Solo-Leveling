package com.virgax.arise.ui

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.health.connect.client.PermissionController
import com.virgax.arise.AriseViewModel
import com.virgax.arise.domain.HealthSnapshot
import com.virgax.arise.health.HealthConnectManager
import com.virgax.arise.ui.theme.AriseColors
import kotlinx.coroutines.launch

/** "Connect your health data" card — Health Connect is Android's hub for
 *  Google Fit, Samsung Health, Fitbit and rings. */
@Composable
fun HealthConnectCard(vm: AriseViewModel) {
    val context = LocalContext.current
    val manager = remember { HealthConnectManager(context) }
    val scope = rememberCoroutineScope()
    var loading by remember { mutableStateOf(false) }

    val launcher = rememberLauncherForActivityResult(
        PermissionController.createRequestPermissionResultContract(),
    ) { granted ->
        if (granted.containsAll(manager.permissions)) {
            scope.launch {
                loading = true
                runCatching { vm.applyHealth(manager.readSnapshot()) }
                loading = false
            }
        }
    }

    LaunchedEffect(Unit) {
        if (manager.isAvailable && !vm.healthConnected && manager.hasPermissions()) {
            loading = true
            runCatching { vm.applyHealth(manager.readSnapshot()) }
            loading = false
        }
    }

    SystemPanel("Health Connect") {
        when {
            vm.healthConnected -> Row(verticalAlignment = Alignment.CenterVertically) {
                Text("✅", fontSize = 18.sp)
                Spacer(Modifier.width(10.dp))
                Column {
                    Text("Linked · real data", color = AriseColors.TextPrimary, fontWeight = FontWeight.Bold)
                    Text("Steps, energy, sleep, HR & weight", color = AriseColors.TextSecondary, fontSize = 11.sp)
                }
            }
            !manager.isAvailable -> Column {
                Text(
                    "Health Connect isn't set up on this device yet.",
                    color = AriseColors.TextSecondary, fontSize = 13.sp,
                )
                Spacer(Modifier.height(10.dp))
                Button(
                    onClick = {
                        runCatching {
                            context.startActivity(
                                Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=com.google.android.apps.healthdata")),
                            )
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                ) { Text("Get Health Connect") }
            }
            else -> Column {
                Text(
                    "Connect Google Fit, Samsung Health, Fitbit & your ring — they all sync into Health Connect.",
                    color = AriseColors.TextSecondary, fontSize = 13.sp,
                )
                Spacer(Modifier.height(10.dp))
                Button(
                    onClick = { launcher.launch(manager.permissions) },
                    enabled = !loading,
                    modifier = Modifier.fillMaxWidth(),
                ) { Text(if (loading) "Reading…" else "Connect Health Connect") }
            }
        }

        // Emulators (e.g. BlueStacks) can't use Health Connect — it demands an
        // encrypted device. This lets you demo the full "connected" experience.
        if (!vm.healthConnected) {
            Spacer(Modifier.height(6.dp))
            TextButton(
                onClick = { vm.applyHealth(HealthSnapshot.sample) },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("Use demo data (emulator / testing)", color = AriseColors.TextSecondary, fontSize = 12.sp)
            }
        }
    }
}

package com.nguendarthurjohann.focusflow.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.nguendarthurjohann.focusflow.ui.viewmodel.SensorViewModel

@Composable
fun DashboardScreen(viewModel: SensorViewModel = hiltViewModel()) {
    val lightLevel by viewModel.lightLevel.collectAsState()
    val isSedentary by viewModel.isSedentary.collectAsState()

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Dashboard (Sensors)", style = MaterialTheme.typography.headlineMedium)
            IconButton(onClick = { /* Toggle Notifications */ }) {
                Icon(Icons.Default.NotificationsActive, contentDescription = "Alerts")
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            item {
                SensorCard(
                    title = "Eye Strain Prevention",
                    value = "Camera Active",
                    status = "Monitoring distance...",
                    icon = Icons.Default.Visibility
                )
            }
            item {
                val lightStatus = if (lightLevel < 50f) "Reading Mode Suggested" else "Optimal Lighting"
                SensorCard(
                    title = "Adaptive Lighting",
                    value = "Light: ${"%.1f".format(lightLevel)} Lux",
                    status = lightStatus,
                    icon = Icons.Default.WbSunny
                )
            }
            item {
                SensorCard(
                    title = "Noise Analysis",
                    value = "Mic Active",
                    status = "Environment Analysis...",
                    icon = Icons.Default.VolumeUp
                )
            }
            item {
                val sedentaryStatus = if (isSedentary) "Take a break! 🏃" else "Movement detected"
                SensorCard(
                    title = "Sedentary Alert",
                    value = if (isSedentary) "Inactive for > 1 min" else "Active",
                    status = sedentaryStatus,
                    icon = Icons.Default.DirectionsRun
                )
            }
        }
    }
}

@Composable
fun SensorCard(title: String, value: String, status: String, icon: ImageVector) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(32.dp), tint = MaterialTheme.colorScheme.primary)
            Spacer(modifier = Modifier.width(16.dp))
            Column {
                Text(title, style = MaterialTheme.typography.titleMedium)
                Text(value, style = MaterialTheme.typography.bodyLarge)
                Text(status, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary)
            }
        }
    }
}

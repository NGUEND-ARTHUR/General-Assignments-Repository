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
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp

@Composable
fun DashboardScreen() {
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
                    value = "Distance: 45cm",
                    status = "Optimal",
                    icon = Icons.Default.Visibility
                )
            }
            item {
                SensorCard(
                    title = "Adaptive Lighting",
                    value = "Light: 300 Lux",
                    status = "Reading Mode Suggested",
                    icon = Icons.Default.WbSunny
                )
            }
            item {
                SensorCard(
                    title = "Noise Analysis",
                    value = "Noise: 55dB",
                    status = "Quiet Environment",
                    icon = Icons.Default.VolumeUp
                )
            }
            item {
                SensorCard(
                    title = "Sedentary Alert",
                    value = "Last Move: 20m ago",
                    status = "Keep going",
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

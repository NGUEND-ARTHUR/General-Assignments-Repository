package com.nguendarthurjohann.focusflow.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun DashboardScreen() {
    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Text("Dashboard (Sensors)", style = MaterialTheme.typography.headlineMedium)
        Spacer(modifier = Modifier.height(16.dp))
        SensorCard("Eye Strain Prevention", "Distance: 45cm", "Optimal")
        SensorCard("Adaptive Lighting", "Light: 300 Lux", "Reading Mode Suggested")
        SensorCard("Noise Analysis", "Noise: 55dB", "Quiet Environment")
        SensorCard("Sedentary Alert", "Last Move: 20m ago", "Keep going")
    }
}

@Composable
fun SensorCard(title: String, value: String, status: String) {
    Card(modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium)
            Text(value, style = MaterialTheme.typography.bodyLarge)
            Text(status, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary)
        }
    }
}

package com.nguendarthurjohann.focusflow.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.nguendarthurjohann.focusflow.ui.viewmodel.FocusViewModel
import com.nguendarthurjohann.focusflow.utils.Resource

@Composable
fun FocusScreen(viewModel: FocusViewModel = hiltViewModel()) {
    val timerState by viewModel.timerState.collectAsState()
    val isRunning by viewModel.isTimerRunning.collectAsState()
    val seeds by viewModel.seeds.collectAsState()

    val displayTime = when (val state = timerState) {
        is Resource.Success -> state.data ?: "25:00"
        is Resource.Loading -> state.data ?: "25:00"
        else -> "25:00"
    }

    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("Focus (Timer & Garden)", style = MaterialTheme.typography.headlineMedium)
        Spacer(modifier = Modifier.height(8.dp))
        Text("Total Seeds: $seeds 🌱", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
        
        Spacer(modifier = Modifier.height(32.dp))
        Text(text = displayTime, style = MaterialTheme.typography.displayLarge)
        
        Spacer(modifier = Modifier.height(32.dp))
        Button(
            onClick = { if (isRunning) viewModel.pauseTimer() else viewModel.startTimer() },
            colors = ButtonDefaults.buttonColors(
                containerColor = if (isRunning) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary
            )
        ) {
            Text(if (isRunning) "Pause Session" else "Start Focus Session")
        }

        Spacer(modifier = Modifier.height(32.dp))
        Text("White Noise Library", style = MaterialTheme.typography.labelLarge)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            FilterChip(selected = true, onClick = {}, label = { Text("Rain 🌧️") })
            FilterChip(selected = false, onClick = {}, label = { Text("Forest 🌲") })
            FilterChip(selected = false, onClick = {}, label = { Text("Café ☕") })
        }

        Spacer(modifier = Modifier.height(48.dp))
        Text("Your Focus Garden", style = MaterialTheme.typography.titleMedium)
        Card(modifier = Modifier.size(200.dp).padding(16.dp)) {
            Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                Text(text = if (seeds > 10) "🌳" else "🌱", style = MaterialTheme.typography.displayLarge)
            }
        }
    }
}

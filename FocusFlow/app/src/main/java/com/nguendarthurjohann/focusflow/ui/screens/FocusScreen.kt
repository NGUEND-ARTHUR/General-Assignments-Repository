package com.nguendarthurjohann.focusflow.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun FocusScreen() {
    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("Focus (Timer & Garden)", style = MaterialTheme.typography.headlineMedium)
        Spacer(modifier = Modifier.height(32.dp))
        Text("25:00", style = MaterialTheme.typography.displayLarge)
        Spacer(modifier = Modifier.height(32.dp))
        Button(onClick = { /* Start Timer */ }) {
            Text("Start Focus Session")
        }
        Spacer(modifier = Modifier.height(48.dp))
        Text("Your Focus Garden", style = MaterialTheme.typography.titleMedium)
        Card(modifier = Modifier.size(200.dp).padding(16.dp)) {
            Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                Text("🌳", style = MaterialTheme.typography.displayLarge)
            }
        }
    }
}

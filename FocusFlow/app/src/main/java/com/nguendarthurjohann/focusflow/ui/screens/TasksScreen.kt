package com.nguendarthurjohann.focusflow.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

@Composable
fun TasksScreen() {
    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Text("Tasks (Eisenhower Matrix)", style = MaterialTheme.typography.headlineMedium)
        Spacer(modifier = Modifier.height(16.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Row(modifier = Modifier.weight(1f)) {
                MatrixQuadrant("Urgent & Important", Color(0xFFFFEBEE), Modifier.weight(1f))
                MatrixQuadrant("Important, Not Urgent", Color(0xFFE8F5E9), Modifier.weight(1f))
            }
            Row(modifier = Modifier.weight(1f)) {
                MatrixQuadrant("Urgent, Not Important", Color(0xFFFFF3E0), Modifier.weight(1f))
                MatrixQuadrant("Neither", Color(0xFFF5F5F5), Modifier.weight(1f))
            }
        }
    }
}

@Composable
fun MatrixQuadrant(title: String, color: Color, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier.padding(4.dp).fillMaxSize(),
        colors = CardDefaults.cardColors(containerColor = color)
    ) {
        Column(modifier = Modifier.padding(8.dp)) {
            Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold)
            Spacer(modifier = Modifier.height(8.dp))
            Text("Add task...", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
        }
    }
}

package com.nguendarthurjohann.focusflow.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.nguendarthurjohann.focusflow.ui.viewmodel.TasksViewModel
import com.nguendarthurjohann.focusflow.data.local.entities.TaskEntity

@Composable
@Composable
fun TasksScreen(viewModel: TasksViewModel = hiltViewModel()) {
    val tasks by viewModel.allTasks.collectAsState()
    var newTaskTitle by remember { mutableStateOf("") }
    var newTaskUrgent by remember { mutableStateOf(false) }
    var newTaskImportant by remember { mutableStateOf(false) }

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Text("Tasks (Eisenhower Matrix)", style = MaterialTheme.typography.headlineMedium)
        Spacer(modifier = Modifier.height(8.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            OutlinedTextField(
                value = newTaskTitle,
                onValueChange = { newTaskTitle = it },
                label = { Text("Task Title") },
                modifier = Modifier.weight(1f)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Button(onClick = {
                if (newTaskTitle.isNotBlank()) {
                    viewModel.addTask(newTaskTitle, newTaskUrgent, newTaskImportant)
                    newTaskTitle = ""
                }
            }) { Text("Add") }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = newTaskUrgent, onCheckedChange = { newTaskUrgent = it })
            Text("Urgent")
            Spacer(modifier = Modifier.width(8.dp))
            Checkbox(checked = newTaskImportant, onCheckedChange = { newTaskImportant = it })
            Text("Important")
        }
        Spacer(modifier = Modifier.height(8.dp))
        Column(modifier = Modifier.weight(1f)) {
            Row(modifier = Modifier.weight(1f)) {
                MatrixQuadrant(
                    title = "Urgent & Important",
                    color = Color(0xFFFFEBEE),
                    tasks = tasks.filter { it.isUrgent && it.isImportant },
                    onToggle = { viewModel.toggleTaskCompletion(it) },
                    onDelete = { viewModel.deleteTask(it) },
                    modifier = Modifier.weight(1f)
                )
                MatrixQuadrant(
                    title = "Important, Not Urgent",
                    color = Color(0xFFE8F5E9),
                    tasks = tasks.filter { !it.isUrgent && it.isImportant },
                    onToggle = { viewModel.toggleTaskCompletion(it) },
                    onDelete = { viewModel.deleteTask(it) },
                    modifier = Modifier.weight(1f)
                )
            }
            Row(modifier = Modifier.weight(1f)) {
                MatrixQuadrant(
                    title = "Urgent, Not Important",
                    color = Color(0xFFFFF3E0),
                    tasks = tasks.filter { it.isUrgent && !it.isImportant },
                    onToggle = { viewModel.toggleTaskCompletion(it) },
                    onDelete = { viewModel.deleteTask(it) },
                    modifier = Modifier.weight(1f)
                )
                MatrixQuadrant(
                    title = "Neither",
                    color = Color(0xFFF5F5F5),
                    tasks = tasks.filter { !it.isUrgent && !it.isImportant },
                    onToggle = { viewModel.toggleTaskCompletion(it) },
                    onDelete = { viewModel.deleteTask(it) },
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
@Composable
fun MatrixQuadrant(
    title: String,
    color: Color,
    tasks: List<TaskEntity>,
    onToggle: (TaskEntity) -> Unit,
    onDelete: (TaskEntity) -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.padding(4.dp).fillMaxSize(),
        colors = CardDefaults.cardColors(containerColor = color)
    ) {
        Column(modifier = Modifier.padding(8.dp)) {
            Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold)
            Spacer(modifier = Modifier.height(8.dp))
            if (tasks.isEmpty()) {
                Text("No tasks", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
            } else {
                tasks.forEach { task ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(checked = task.isCompleted, onCheckedChange = { onToggle(task) })
                        Text(task.title, style = MaterialTheme.typography.bodyMedium)
                        Spacer(modifier = Modifier.weight(1f))
                        IconButton(onClick = { onDelete(task) }) {
                            Icon(Icons.Default.Delete, contentDescription = "Delete")
                        }
                    }
                }
            }
        }
    }
}

package exercise_8_logger_delegation

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Terminal
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Exercise 8: Implement a Logger Using Delegation
 * 
 * Task:
 * Create a simple logging system using delegation.
 */

interface Logger {
    fun log(message: String): String
}

class ConsoleLogger : Logger {
    override fun log(message: String) = "Console: $message"
}

class FileLogger : Logger {
    override fun log(message: String) = "File: $message"
}

// Class delegation using the 'by' keyword
class Application(logger: Logger) : Logger by logger

@Composable
fun LoggerDelegationScreen() {
    var logs by remember { mutableStateOf(listOf<String>()) }
    val consoleApp = remember { Application(ConsoleLogger()) }
    val fileApp = remember { Application(FileLogger()) }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Logger Delegation",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(24.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = { logs = logs + consoleApp.log("Application started") },
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Default.Terminal, contentDescription = null)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Log to Console")
                }
                Button(
                    onClick = { logs = logs + fileApp.log("Error occurred") },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary)
                ) {
                    Icon(Icons.Default.Description, contentDescription = null)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Log to File")
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = "Log History:",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.align(Alignment.Start)
            )
            
            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

            LazyColumn(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(logs) { log ->
                    LogItem(log)
                }
            }
        }
    }
}

@Composable
fun LogItem(message: String) {
    val isFile = message.startsWith("File")
    val color = if (isFile) MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.primary
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = color.copy(alpha = 0.1f))
    ) {
        Text(
            text = message,
            modifier = Modifier.padding(12.dp),
            fontWeight = FontWeight.Medium,
            color = color
        )
    }
}

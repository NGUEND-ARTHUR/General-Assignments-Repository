package com.example.gradecalculator.ui.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun ManualEntryScreen(
    onCalculate: (String, Double?) -> Unit,
    onImportExcel: (Uri) -> Unit,
    onCreateTestFile: (Uri) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var score by remember { mutableStateOf("") }
    val context = LocalContext.current

    val importLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument(),
        onResult = { uri -> uri?.let { onImportExcel(it) } }
    )

    val createTestFileLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
        onResult = { uri -> uri?.let { onCreateTestFile(it) } }
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        OutlinedTextField(
            value = name,
            onValueChange = { name = it },
            label = { Text("Student Name") },
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        OutlinedTextField(
            value = score,
            onValueChange = { score = it },
            label = { Text("Score (0-100)") },
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(32.dp))

        Button(
            onClick = { 
                val scoreDouble = score.toDoubleOrNull()
                onCalculate(name, scoreDouble)
                name = ""
                score = ""
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(64.dp),
            shape = MaterialTheme.shapes.medium
        ) {
            Text("Calculate Grade", fontSize = 18.sp)
        }

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "--- OR ---",
            color = Color.Gray,
            fontSize = 16.sp,
            modifier = Modifier.padding(vertical = 16.dp)
        )

        OutlinedButton(
            onClick = { importLauncher.launch(arrayOf("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.ms-excel")) },
            modifier = Modifier
                .fillMaxWidth()
                .height(60.dp),
            shape = MaterialTheme.shapes.medium
        ) {
            Text("Import Excel File", fontSize = 18.sp)
        }

        TextButton(
            onClick = { createTestFileLauncher.launch("test_students.xlsx") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp)
        ) {
            Text("Create Test Excel File", color = Color(0xFF1976D2), fontSize = 14.sp)
        }
    }
}

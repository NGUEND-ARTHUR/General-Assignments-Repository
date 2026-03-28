package com.example.gradecalculator.ui.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Save
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.gradecalculator.model.Student

@Composable
fun ResultsScreen(
    students: List<Student>,
    onExportExcel: (Uri) -> Unit,
    onExportPdf: (Uri) -> Unit,
    onExportCsv: (Uri) -> Unit,
    onEdit: (Student, String, Double?) -> Unit,
    onDelete: (Student) -> Unit
) {
    var editingStudent by remember { mutableStateOf<Student?>(null) }
    var showExportMenu by remember { mutableStateOf(false) }
    
    val excelLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
        onResult = { uri -> uri?.let { onExportExcel(it) } }
    )

    val pdfLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument("application/pdf"),
        onResult = { uri -> uri?.let { onExportPdf(it) } }
    )

    val csvLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument("text/csv"),
        onResult = { uri -> uri?.let { onExportCsv(it) } }
    )

    Scaffold(
        floatingActionButton = {
            Column(horizontalAlignment = Alignment.End) {
                if (showExportMenu) {
                    ExportOptionFab("PDF", Icons.Default.Save) { 
                        showExportMenu = false
                        pdfLauncher.launch("grade_report.pdf") 
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    ExportOptionFab("CSV", Icons.Default.Save) { 
                        showExportMenu = false
                        csvLauncher.launch("grade_report.csv") 
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    ExportOptionFab("Excel", Icons.Default.Save) { 
                        showExportMenu = false
                        excelLauncher.launch("grade_report.xlsx") 
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                }
                FloatingActionButton(onClick = { showExportMenu = !showExportMenu }) {
                    Icon(Icons.Default.Save, contentDescription = "Export Menu")
                }
            }
        }
    ) { padding ->
        if (students.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("No students added yet", color = Color.Gray)
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(8.dp)
            ) {
                items(students) { student ->
                    StudentItem(
                        student = student, 
                        onEditClick = { editingStudent = student }, 
                        onDeleteClick = { onDelete(student) }
                    )
                }
            }
        }

        editingStudent?.let { student ->
            EditStudentDialog(
                student = student,
                onDismiss = { editingStudent = null },
                onConfirm = { name, score ->
                    onEdit(student, name, score)
                    editingStudent = null
                }
            )
        }
    }
}

@Composable
fun ExportOptionFab(label: String, icon: androidx.compose.ui.graphics.vector.ImageVector, onClick: () -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Surface(
            shape = MaterialTheme.shapes.small,
            color = MaterialTheme.colorScheme.surfaceVariant,
            modifier = Modifier.padding(end = 8.dp)
        ) {
            Text(label, modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp), style = MaterialTheme.typography.labelMedium)
        }
        SmallFloatingActionButton(onClick = onClick) {
            Icon(icon, contentDescription = label)
        }
    }
}

@Composable
fun StudentItem(student: Student, onEditClick: () -> Unit, onDeleteClick: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp).fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(student.name, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                Text("Score: ${student.score ?: "N/A"}", color = Color.Gray)
            }
            
            Surface(
                modifier = Modifier.size(48.dp),
                shape = MaterialTheme.shapes.small,
                color = MaterialTheme.colorScheme.secondaryContainer
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(student.grade, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                }
            }

            var expanded by remember { mutableStateOf(false) }
            Box {
                IconButton(onClick = { expanded = true }) {
                    Icon(Icons.Default.MoreVert, contentDescription = "Menu")
                }
                DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                    DropdownMenuItem(
                        text = { Text("Edit") }, 
                        onClick = { expanded = false; onEditClick() }
                    )
                    DropdownMenuItem(
                        text = { Text("Delete") }, 
                        onClick = { expanded = false; onDeleteClick() }
                    )
                }
            }
        }
    }
}

@Composable
fun EditStudentDialog(
    student: Student,
    onDismiss: () -> Unit,
    onConfirm: (String, Double?) -> Unit
) {
    var name by remember { mutableStateOf(student.name) }
    var score by remember { mutableStateOf(student.score?.toString() ?: "") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Student") },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Student Name") },
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = score,
                    onValueChange = { score = it },
                    label = { Text("Score (0-100)") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(onClick = { onConfirm(name, score.toDoubleOrNull()) }) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

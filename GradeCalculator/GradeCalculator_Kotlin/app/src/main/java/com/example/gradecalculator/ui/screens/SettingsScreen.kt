package com.example.gradecalculator.ui.screens

import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.Language
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.core.os.LocaleListCompat

@Composable
fun SettingsScreen(
    onClearAll: () -> Unit
) {
    var showDeleteDialog by remember { mutableStateOf(false) }
    var showLanguageDialog by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "Settings",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        // Language Setting
        SettingsCard(
            title = "Language",
            description = "Change application language",
            icon = Icons.Default.Language,
            onClick = { showLanguageDialog = true }
        )

        // Database Setting
        SettingsCard(
            title = "Database Management",
            description = "Remove all student records permanently",
            icon = Icons.Default.DeleteSweep,
            iconColor = Color.Red,
            onClick = { showDeleteDialog = true }
        )
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Confirm Clear") },
            text = { Text("Are you sure you want to delete all student records? This action cannot be undone.") },
            confirmButton = {
                TextButton(onClick = { 
                    onClearAll()
                    showDeleteDialog = false 
                }) {
                    Text("Delete All", color = Color.Red)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    if (showLanguageDialog) {
        AlertDialog(
            onDismissRequest = { showLanguageDialog = false },
            title = { Text("Select Language") },
            text = {
                Column {
                    LanguageOption("English", "en") { showLanguageDialog = false }
                    LanguageOption("Français", "fr") { showLanguageDialog = false }
                }
            },
            confirmButton = {}
        )
    }
}

@Composable
fun SettingsCard(title: String, description: String, icon: androidx.compose.ui.graphics.vector.ImageVector, iconColor: Color = Color.Unspecified, onClick: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        onClick = onClick
    ) {
        Row(
            modifier = Modifier.padding(16.dp).fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleMedium)
                Text(description, style = MaterialTheme.typography.bodySmall)
            }
            Icon(icon, contentDescription = null, tint = iconColor)
        }
    }
}

@Composable
fun LanguageOption(label: String, code: String, onSelected: () -> Unit) {
    TextButton(
        onClick = {
            val appLocales: LocaleListCompat = LocaleListCompat.forLanguageTags(code)
            AppCompatDelegate.setApplicationLocales(appLocales)
            onSelected()
        },
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(label, modifier = Modifier.fillMaxWidth(), textAlign = androidx.compose.ui.text.style.TextAlign.Start)
    }
}

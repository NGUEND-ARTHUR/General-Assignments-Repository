package com.nguendarthurjohann.focusflow.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/**
 * UI Component with Modifiers and Material Design 3
 */
@Composable
fun FilterSection(options: List<String>, onOptionSelected: (String) -> Unit) {
    Text(
        text = "Quick Filters",
        style = MaterialTheme.typography.titleMedium,
        modifier = Modifier.padding(8.dp)
    )

    // Using LazyRow for dynamic list display
    LazyRow(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(options) { option ->
            AssistChip(
                onClick = { onOptionSelected(option) },
                label = { Text(option) }
            )
        }
    }
}

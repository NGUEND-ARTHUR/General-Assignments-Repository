package exercise_7_generic_function

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Exercise 7: Generic Function with Constraints
 * 
 * Task:
 * Write a generic function maxOf that returns the maximum element from a list.
 * The function should work for any type that implements Comparable<T>.
 */

fun <T : Comparable<T>> maxOf(list: List<T>): T? {
    if (list.isEmpty()) return null
    var max = list[0]
    for (i in 1 until list.size) {
        if (list[i] > max) {
            max = list[i]
        }
    }
    return max
}

@Composable
fun GenericFunctionScreen() {
    val intList = listOf(3, 7, 2, 9)
    val stringList = listOf("apple", "banana", "kiwi")
    val emptyList = emptyList<Int>()

    val maxInt = remember { maxOf(intList) }
    val maxString = remember { maxOf(stringList) }
    val maxEmpty = remember { maxOf(emptyList) }

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
                text = "Generic maxOf Function",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(24.dp))

            ResultCard(title = "Integers: $intList", result = maxInt?.toString() ?: "null")
            Spacer(modifier = Modifier.height(16.dp))
            ResultCard(title = "Strings: $stringList", result = maxString ?: "null")
            Spacer(modifier = Modifier.height(16.dp))
            ResultCard(title = "Empty List: []", result = maxEmpty?.toString() ?: "null")
        }
    }
}

@Composable
fun ResultCard(title: String, result: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(text = title, style = MaterialTheme.typography.labelLarge)
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Max Value: $result",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

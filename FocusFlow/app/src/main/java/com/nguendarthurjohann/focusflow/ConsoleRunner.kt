package com.nguendarthurjohann.focusflow

import com.nguendarthurjohann.focusflow.utils.Resource
import com.nguendarthurjohann.focusflow.utils.processData

/**
 * Console Version: FocusFlow
 * Demonstrates basic logic that can run on any machine (PC, Console, etc.)
 */
fun main() {
    println("--- FocusFlow: Console Runner ---")

    val states = listOf(
        FocusState(300.0, 45.0, 50.0, false, "S001"),
        FocusState(80.0, 25.0, 65.0, true, "S002")
    )

    // Using Generic Higher-Order Function
    val summaries = states.processData { 
        "Session ${it.sessionID}: ${if (it.isSedentary) "Alert!" else "Active"}"
    }

    // Using Generic Resource Class
    val resource = Resource.Success(summaries)
    
    when (resource) {
        is Resource.Success -> {
            println("Data Processed Successfully:")
            resource.data?.forEach { println("- $it") }
        }
        else -> println("Processing...")
    }
}

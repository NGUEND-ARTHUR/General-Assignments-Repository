/**
 * PROJECT: FocusFlow
 * MILESTONE 1 & 2: Data Modeling and Functional Logic
 * SUBMITTED BY: Arthur Johann
 */

package com.nguendarthurjohann.focusflow

/**
 * Milestone 1: Data Class representing the state of a focus session.
 * 
 * @property lightLevelLux The ambient light level in Lux. Null if sensor is unavailable.
 * @property faceDistanceCm Proximity of the user's face to the screen. Null if camera is off.
 * @property noiseDb Background noise level in Decibels.
 * @property isSedentary Whether the user has been immobile for too long.
 * @property sessionID Unique identifier for the current focus session.
 */
data class FocusState(
    val lightLevelLux: Double?, 
    val faceDistanceCm: Double?, 
    val noiseDb: Double, 
    val isSedentary: Boolean,
    val sessionID: String
)

/**
 * Milestone 2: Functional Logic
 */

// Function 1: Validation - Checks if environmental conditions are safe for focus
fun FocusState.isEnvironmentHealthy(): Boolean {
    val isLightOk = lightLevelLux == null || lightLevelLux > 100.0
    val isNoiseOk = noiseDb < 70.0
    return isLightOk && isNoiseOk
}

// Function 2: Formatting - Returns a summary of the current state
fun FocusState.formatStatus(): String {
    val distanceStatus = faceDistanceCm?.let { if (it < 30.0) "Too Close!" else "Good Distance" } ?: "Distance Unknown"
    val sedentaryStatus = if (isSedentary) "Time to Stretch! 🏃" else "Active"
    return "Session $sessionID: $distanceStatus | $sedentaryStatus"
}

// Higher-order function: Processes a list of states and applies an action
fun processFocusHistory(history: List<FocusState>, action: (FocusState) -> Unit) {
    for (state in history) {
        action(state)
    }
}

/**
 * Demonstration main()
 */
fun main() {
    val history = listOf(
        FocusState(300.0, 45.0, 50.0, false, "S001"),
        FocusState(80.0, 25.0, 65.0, true, "S002"), // Low light, too close, sedentary
        FocusState(400.0, 50.0, 85.0, false, "S003"), // High noise
        FocusState(null, null, 40.0, false, "S004")
    )

    println("--- Milestone 2: FocusFlow Demonstration ---\n")

    // 1. Collection Operation: Filter healthy environments
    println("1. Healthy Environments:")
    val healthyStates = history.filter { it.isEnvironmentHealthy() }
    healthyStates.forEach { println(it.formatStatus()) }

    // 2. Custom Higher-order function with Lambda
    println("\n2. Processing Session Alerts:")
    processFocusHistory(history) { state ->
        if (state.isSedentary || (state.faceDistanceCm ?: 40.0) < 30.0) {
            println("ALERT in Session ${state.sessionID}: Check posture or take a break!")
        }
    }
}

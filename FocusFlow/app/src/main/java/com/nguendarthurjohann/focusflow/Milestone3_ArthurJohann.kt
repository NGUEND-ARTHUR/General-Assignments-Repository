/**
 * PROJECT: FocusFlow
 * MILESTONE 3: Object-Oriented Domain Model
 * SUBMITTED BY: Arthur Johann
 */

package com.nguendarthurjohann.focusflow

// 1. Interface for common behavior: Reportable
interface FocusReportable {
    fun generateReport(): String
}

// 2. Abstract class representing the core entity "FocusSession"
abstract class FocusSession(val sessionID: String) : FocusReportable {
    abstract val sessionType: String
    
    // Override toString() to provide a base string representation
    override fun toString(): String {
        return "[$sessionType] Session ID: $sessionID"
    }
}

// 3. Data class implementation for a "Solo Focus Session"
data class SoloSession(
    val id: String,
    val duration: Int,
    val focusScore: Int
) : FocusSession(id) {
    override val sessionType: String = "SOLO_FOCUS"

    override fun generateReport(): String {
        return "Solo Report: Focus Score = $focusScore% | Duration = $duration mins"
    }

    override fun toString(): String {
        return "${super.toString()} | Score: $focusScore"
    }
}

// 4. Another concrete subclass for "Study Room Session" (Polymorphism)
class StudyRoomSession(
    id: String,
    val participantsCount: Int
) : FocusSession(id) {
    override val sessionType: String = "STUDY_GROUP"

    override fun generateReport(): String {
        return "Study Group Report: Room $sessionID has $participantsCount active students."
    }
}

/**
 * Main function showcasing the OOP hierarchy, inheritance, and polymorphism.
 */
fun main() {
    println("--- Milestone 3: FocusFlow OOP Domain Model ---\n")

    // Demonstrate Polymorphism: Storing different subclass instances in a collection
    val sessions: List<FocusSession> = listOf(
        SoloSession("S001", 25, 95),
        SoloSession("S002", 50, 78),
        StudyRoomSession("R101", 12),
        SoloSession("S003", 25, 65)
    )

    // Iterate and call overridden methods (Polymorphism in action)
    sessions.forEach { session ->
        println("Session Info: $session") // Calls overridden toString()
        println("Action: ${session.generateReport()}") // Calls polymorphic generateReport()
        println("--------------------------------------------------")
    }

    // Showcase: Accessing data class specific features (copying)
    val original = SoloSession("S001", 25, 95)
    val improved = original.copy(focusScore = 100)
    println("\nData Class Feature (copy): Original Score = ${original.focusScore}, Improved = ${improved.focusScore}")
}

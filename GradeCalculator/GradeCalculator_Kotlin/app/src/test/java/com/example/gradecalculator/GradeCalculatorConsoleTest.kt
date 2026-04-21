package com.example.gradecalculator

import com.example.gradecalculator.utils.GradeUtils
import org.junit.Test

/**
 * This test allows you to run the grading logic directly in the IDE console
 * without needing to launch the full Android app or emulator.
 */
class GradeCalculatorConsoleTest {
    @Test
    fun runCalculatorInConsole() {
        println("\n" + "=".repeat(46))
        println("   STUDENT GRADE CALCULATOR - CONSOLE MODE    ")
        println("=".repeat(46))

        val students = listOf(
            "Alice" to 95.0,
            "Bob" to 82.5,
            "Charlie" to 74.0,
            "Daisy" to 61.0,
            "Ethan" to 45.0,
            "Fiona" to null // Testing the "No score" requirement
        )

        students.forEach { (name, score) ->
            val grade = GradeUtils.calculateGrade(score)
            val scoreDisplay = GradeUtils.formatScore(score)
            
            // Following the required print format: "[name] scored [score] : Grade [grade]"
            if (score != null) {
                println("$name scored $scoreDisplay : Grade $grade")
            } else {
                println("No score for $name")
            }
        }
        
        println("=".repeat(46) + "\n")
    }
}
